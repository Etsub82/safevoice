using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _config;
    private readonly IAuditLogService _audit;
    private readonly INotificationService _notification;

    public AuthService(AppDbContext db, IConfiguration config, IAuditLogService audit, INotificationService notification)
    {
        _db = db;
        _config = config;
        _audit = audit;
        _notification = notification;
    }

    public async Task RegisterAsync(RegisterRequest request)
    {
        // P2: phone number uniqueness
        if (await _db.Users.AnyAsync(u => u.PhoneNumber == request.PhoneNumber))
            throw new InvalidOperationException("PHONE_IN_USE");

        var user = new User
        {
            PhoneNumber = request.PhoneNumber,
            PasswordHash = HashPassword(request.Password),
            Role = Enum.Parse<UserRole>(request.Role, ignoreCase: true),
            PreferredLanguage = request.PreferredLanguage,
            DisplayName = request.DisplayName,
            GuardianChildName = request.GuardianChildName,
            GuardianRelationship = request.GuardianRelationship,
            IsActive = false
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        await IssueOtpAsync(user, request.PhoneNumber);
        await _audit.LogAsync(AuditEventTypes.Register, user.Id);
    }

    /// <summary>
    /// PIN-based registration — no OTP step required.
    /// The PIN is treated as the password: it is BCrypt-hashed before storage.
    /// The account is immediately activated so the user can log in right away.
    /// </summary>
    public async Task<TokenResponse> RegisterWithPinAsync(RegisterWithPinRequest request)
    {
        // Validate PIN: exactly 6 digits
        if (string.IsNullOrWhiteSpace(request.Pin) || request.Pin.Length != 6 || !request.Pin.All(char.IsDigit))
            throw new InvalidOperationException("INVALID_PIN");

        // Phone number uniqueness
        if (await _db.Users.AnyAsync(u => u.PhoneNumber == request.PhoneNumber))
            throw new InvalidOperationException("PHONE_IN_USE");

        var user = new User
        {
            PhoneNumber = request.PhoneNumber,
            PasswordHash = HashPassword(request.Pin),   // BCrypt hashes the PIN
            Role = Enum.Parse<UserRole>(request.Role, ignoreCase: true),
            PreferredLanguage = request.PreferredLanguage,
            DisplayName = request.DisplayName,
            GuardianChildName = request.GuardianChildName,
            GuardianRelationship = request.GuardianRelationship,
            IsActive = true,    // immediately active — no OTP step
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        await _audit.LogAsync(AuditEventTypes.Register, user.Id);

        return await GenerateTokensAsync(user);
    }

    public async Task<TokenResponse> VerifyOtpAsync(OtpVerifyRequest request)
    {
        // P1: OTP correctness
        var otp = await _db.OtpRequests
            .Where(o => o.PhoneNumber == request.PhoneNumber && !o.IsUsed)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync()
            ?? throw new InvalidOperationException("OTP_NOT_FOUND");

        if (otp.ExpiresAt < DateTime.UtcNow)
            throw new InvalidOperationException("OTP_EXPIRED");

        if (!string.Equals(HashString(request.Otp), otp.OtpHash, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("OTP_INVALID");

        otp.IsUsed = true;

        var user = await _db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == request.PhoneNumber)
            ?? throw new InvalidOperationException("USER_NOT_FOUND");

        user.IsActive = true;
        await _db.SaveChangesAsync();

        return await GenerateTokensAsync(user);
    }

    public async Task<TokenResponse> LoginAsync(LoginRequest request)
    {
        // Support both phone-based (mobile) and username-based (portal) login
        User? user = null;
        if (!string.IsNullOrWhiteSpace(request.Username))
            user = await _db.Users.FirstOrDefaultAsync(u => u.Username == request.Username);
        else if (!string.IsNullOrWhiteSpace(request.PhoneNumber))
            user = await _db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == request.PhoneNumber);

        if (user == null) throw new UnauthorizedAccessException("INVALID_CREDENTIALS");

        // Reject inactive accounts
        if (!user.IsActive)
            throw new UnauthorizedAccessException("INVALID_CREDENTIALS");

        // P11: brute-force lockout
        if (user.IsLocked && user.LockedUntil > DateTime.UtcNow)
            throw new InvalidOperationException($"ACCOUNT_LOCKED:{user.LockedUntil:O}");

        if (user.IsLocked && user.LockedUntil <= DateTime.UtcNow)
        {
            user.IsLocked = false;
            user.FailedLoginAttempts = 0;
        }

        if (!VerifyHash(request.Password, user.PasswordHash))
        {
            user.FailedLoginAttempts++;
            if (user.FailedLoginAttempts >= 5)
            {
                user.IsLocked = true;
                user.LockedUntil = DateTime.UtcNow.AddMinutes(30);
                await _audit.LogAsync(AuditEventTypes.AccountLocked, user.Id);
                if (!string.IsNullOrWhiteSpace(user.PhoneNumber))
                    await _notification.SendSmsAsync(user.PhoneNumber,
                        "Your SafeVoice account has been locked for 30 minutes due to multiple failed login attempts.");
            }
            await _db.SaveChangesAsync();
            throw new UnauthorizedAccessException("INVALID_CREDENTIALS");
        }

        user.FailedLoginAttempts = 0;
        user.IsLocked = false;
        await _db.SaveChangesAsync();

        var tokens = await GenerateTokensAsync(user);
        await _audit.LogAsync(AuditEventTypes.Login, user.Id);
        return tokens;
    }

    public async Task<TokenResponse> RefreshTokenAsync(string refreshToken)
    {
        var tokenHash = HashString(refreshToken);
        var stored = await _db.RefreshTokens
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash)
            ?? throw new UnauthorizedAccessException("SESSION_EXPIRED");

        // P9: invalid refresh token forces re-login
        if (stored.IsRevoked || stored.ExpiresAt < DateTime.UtcNow)
        {
            stored.IsRevoked = true;
            await _db.SaveChangesAsync();
            throw new UnauthorizedAccessException("SESSION_EXPIRED");
        }

        stored.IsRevoked = true;
        await _db.SaveChangesAsync();

        return await GenerateTokensAsync(stored.User);
    }

    public async Task LogoutAsync(string refreshToken)
    {
        var tokenHash = HashString(refreshToken);
        var stored = await _db.RefreshTokens.FirstOrDefaultAsync(r => r.TokenHash == tokenHash);
        if (stored != null)
        {
            stored.IsRevoked = true;
            await _db.SaveChangesAsync();
        }
        if (stored?.UserId != null)
            await _audit.LogAsync(AuditEventTypes.Logout, stored.UserId);
    }

    public async Task RequestOtpAsync(string phoneNumber)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phoneNumber);
        if (user == null) return; // Don't reveal if phone exists
        await IssueOtpAsync(user, phoneNumber);
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request)
    {
        var otp = await _db.OtpRequests
            .Where(o => o.PhoneNumber == request.PhoneNumber && !o.IsUsed)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync()
            ?? throw new InvalidOperationException("OTP_NOT_FOUND");

        if (otp.ExpiresAt < DateTime.UtcNow) throw new InvalidOperationException("OTP_EXPIRED");
        if (!string.Equals(HashString(request.Otp), otp.OtpHash, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("OTP_INVALID");

        otp.IsUsed = true;
        var user = await _db.Users.FirstOrDefaultAsync(u => u.PhoneNumber == request.PhoneNumber)
            ?? throw new InvalidOperationException("USER_NOT_FOUND");

        user.PasswordHash = HashPassword(request.NewPassword);
        await _db.SaveChangesAsync();
        await _audit.LogAsync(AuditEventTypes.PasswordReset, user.Id);
    }

    public async Task<User?> GetUserByIdAsync(Guid userId) =>
        await _db.Users.FindAsync(userId);

    // --- Helpers ---

    private async Task<TokenResponse> GenerateTokensAsync(User user)
    {
        var jwtKey = _config["Jwt:Key"] ?? throw new InvalidOperationException("JWT key not configured");
        var jwtExpiry = int.Parse(_config["Jwt:ExpiryMinutes"] ?? "15");

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Role, user.Role.ToString()),
        };
        if (!string.IsNullOrWhiteSpace(user.PhoneNumber))
            claims.Add(new Claim(ClaimTypes.MobilePhone, user.PhoneNumber));
        if (!string.IsNullOrWhiteSpace(user.Username))
            claims.Add(new Claim(ClaimTypes.Name, user.Username));
        if (!string.IsNullOrWhiteSpace(user.Organization))
            claims.Add(new Claim("organization", user.Organization));
        if (!string.IsNullOrWhiteSpace(user.Jurisdiction))
            claims.Add(new Claim("jurisdiction", user.Jurisdiction));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        // P7: JWT expiry = exactly jwtExpiry minutes from now
        var jwt = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(jwtExpiry),
            signingCredentials: creds);

        var accessToken = new JwtSecurityTokenHandler().WriteToken(jwt);

        // P7: Refresh token expiry = exactly 7 days
        var rawRefresh = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        var refreshEntity = new RefreshToken
        {
            UserId = user.Id,
            TokenHash = HashString(rawRefresh),
            ExpiresAt = DateTime.UtcNow.AddDays(7),
        };
        _db.RefreshTokens.Add(refreshEntity);
        await _db.SaveChangesAsync();

        var portalUser = new PortalUserInfo(
            user.Id.ToString(),
            user.Username ?? user.PhoneNumber,
            user.Role.ToString(),
            user.Organization,
            user.Jurisdiction);

        return new TokenResponse(accessToken, rawRefresh, user.Id.ToString(), user.Role.ToString(), portalUser);
    }

    private async Task IssueOtpAsync(User user, string phoneNumber)
    {
        var otp = RandomNumberGenerator.GetInt32(100000, 999999).ToString();
        var otpRequest = new OtpRequest
        {
            UserId = user.Id,
            PhoneNumber = phoneNumber,
            OtpHash = HashString(otp),
            ExpiresAt = DateTime.UtcNow.AddMinutes(10), // 10-minute window
        };
        _db.OtpRequests.Add(otpRequest);
        await _db.SaveChangesAsync();

        await _notification.SendSmsAsync(phoneNumber, $"Your SafeVoice verification code is: {otp}");
        await _audit.LogAsync(AuditEventTypes.OtpRequested, user.Id);
    }

    private static string HashPassword(string password) =>
        BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12);

    private static bool VerifyHash(string input, string hash)
    {
        try { return BCrypt.Net.BCrypt.Verify(input, hash); }
        catch { return false; }
    }

    private static string HashString(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
