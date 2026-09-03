using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SafeVoice.Core.Interfaces;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;
    private readonly IAuditLogService _audit;

    public AuthController(IAuthService auth, IAuditLogService audit)
    {
        _auth = auth;
        _audit = audit;
    }

    // ── Legacy OTP-based register (kept for portal/admin tooling) ─────────
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            await _auth.RegisterAsync(request);
            return Ok(new { message = "Registration successful. Check your phone for the OTP." });
        }
        catch (InvalidOperationException ex) when (ex.Message == "PHONE_IN_USE")
        {
            return Conflict(new { error = "PHONE_IN_USE" });
        }
    }

    // ── PIN-based registration (victim mobile app) ─────────────────────────
    [HttpPost("register-pin")]
    [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("auth")]
    public async Task<IActionResult> RegisterWithPin([FromBody] RegisterWithPinDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.PhoneNumber))
            return BadRequest(new { error = "PHONE_REQUIRED" });
        if (string.IsNullOrWhiteSpace(dto.Pin) || dto.Pin.Length != 6 || !dto.Pin.All(char.IsDigit))
            return BadRequest(new { error = "INVALID_PIN", message = "PIN must be exactly 6 digits." });
        if (dto.Pin != dto.ConfirmPin)
            return BadRequest(new { error = "PIN_MISMATCH", message = "PINs do not match." });

        try
        {
            var tokens = await _auth.RegisterWithPinAsync(new RegisterWithPinRequest(
                dto.PhoneNumber, dto.Pin,
                dto.Role ?? "Victim",
                dto.PreferredLanguage ?? "en",
                dto.DisplayName,
                dto.GuardianChildName,
                dto.GuardianRelationship));

            Response.Cookies.Append("refreshToken", tokens.RefreshToken, new CookieOptions
            {
                HttpOnly = true, Secure = true, SameSite = SameSiteMode.Strict,
                Expires = DateTimeOffset.UtcNow.AddDays(7),
            });

            return Ok(new
            {
                tokens.AccessToken, tokens.RefreshToken,
                tokens.UserId, tokens.Role, tokens.User,
            });
        }
        catch (InvalidOperationException ex) when (ex.Message == "PHONE_IN_USE")
        {
            return Conflict(new { error = "PHONE_IN_USE", message = "This phone number is already registered." });
        }
        catch (InvalidOperationException ex) when (ex.Message == "INVALID_PIN")
        {
            return BadRequest(new { error = "INVALID_PIN" });
        }
    }

    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] OtpVerifyRequest request)
    {
        try
        {
            var tokens = await _auth.VerifyOtpAsync(request);
            return Ok(tokens);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("login")]
    [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("auth")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var tokens = await _auth.LoginAsync(request);
            await _audit.LogAsync("LOGIN", null, null, HttpContext.Connection.RemoteIpAddress?.ToString());

            Response.Cookies.Append("refreshToken", tokens.RefreshToken, new CookieOptions
            {
                HttpOnly = true,
                Secure = true,
                SameSite = SameSiteMode.Strict,
                Expires = DateTimeOffset.UtcNow.AddDays(7),
            });

            return Ok(new
            {
                tokens.AccessToken,
                tokens.RefreshToken,
                tokens.UserId,
                tokens.Role,
                tokens.User,
            });
        }
        catch (InvalidOperationException ex) when (ex.Message.StartsWith("ACCOUNT_LOCKED"))
        {
            var unlockAt = ex.Message.Split(':').Length > 1 ? ex.Message.Split(':')[1] : "";
            return StatusCode(423, new { error = "ACCOUNT_LOCKED", unlockAt });
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized(new { error = "INVALID_CREDENTIALS" });
        }
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest? request)
    {
        var token = request?.RefreshToken;
        if (string.IsNullOrWhiteSpace(token))
            token = Request.Cookies["refreshToken"];
        if (string.IsNullOrWhiteSpace(token))
            return Unauthorized(new { error = "SESSION_EXPIRED" });

        try
        {
            var tokens = await _auth.RefreshTokenAsync(token);

            Response.Cookies.Append("refreshToken", tokens.RefreshToken, new CookieOptions
            {
                HttpOnly = true,
                Secure = true,
                SameSite = SameSiteMode.Strict,
                Expires = DateTimeOffset.UtcNow.AddDays(7),
            });

            return Ok(new { tokens.AccessToken, tokens.User });
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized(new { error = "SESSION_EXPIRED" });
        }
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest? request)
    {
        var token = request?.RefreshToken ?? Request.Cookies["refreshToken"] ?? string.Empty;
        await _auth.LogoutAsync(token);
        Response.Cookies.Delete("refreshToken");
        return Ok();
    }

    [HttpPost("request-otp")]
    public async Task<IActionResult> RequestOtp([FromBody] OtpRequestBody request)
    {
        await _auth.RequestOtpAsync(request.PhoneNumber);
        return Ok(new { message = "OTP sent if phone number is registered." });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        try
        {
            await _auth.ResetPasswordAsync(request);
            return Ok(new { message = "Password reset successful." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetMe()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user = await _auth.GetUserByIdAsync(userId);
        if (user == null) return NotFound();
        return Ok(new
        {
            user.Id,
            user.PhoneNumber,
            Username = user.Username,
            Role = user.Role.ToString(),
            user.DisplayName,
            user.PreferredLanguage,
            user.Organization,
            user.Jurisdiction,
            user.IsActive,
        });
    }
}

public record RefreshRequest(string? RefreshToken);
public record LogoutRequest(string? RefreshToken);
public record OtpRequestBody(string PhoneNumber);

/// <summary>DTO for PIN-based victim registration.</summary>
public record RegisterWithPinDto(
    string PhoneNumber,
    string Pin,
    string ConfirmPin,
    string? Role,
    string? PreferredLanguage,
    string? DisplayName,
    string? GuardianChildName,
    string? GuardianRelationship);
