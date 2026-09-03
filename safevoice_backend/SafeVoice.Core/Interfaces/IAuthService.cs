using SafeVoice.Core.Entities;

namespace SafeVoice.Core.Interfaces;

public record RegisterRequest(
    string PhoneNumber,
    string Password,
    string Role,
    string PreferredLanguage,
    string? DisplayName,
    string? GuardianChildName,
    string? GuardianRelationship);

/// <summary>PIN-based registration — no OTP required. Used by mobile victim app.</summary>
public record RegisterWithPinRequest(
    string PhoneNumber,
    string Pin,
    string Role,
    string PreferredLanguage,
    string? DisplayName,
    string? GuardianChildName,
    string? GuardianRelationship);

// Support both phone-based (mobile) and username-based (portal) login
public record LoginRequest(
    [property: System.Text.Json.Serialization.JsonPropertyName("phoneNumber")]
    string? PhoneNumber,
    [property: System.Text.Json.Serialization.JsonPropertyName("password")]
    string Password,
    [property: System.Text.Json.Serialization.JsonPropertyName("username")]
    string? Username = null);

public record PortalUserInfo(
    string Id,
    string? Username,
    string Role,
    string? Organization,
    string? Jurisdiction);

public record TokenResponse(
    string AccessToken,
    string RefreshToken,
    string UserId,
    string Role,
    PortalUserInfo? User = null);

public record OtpVerifyRequest(string PhoneNumber, string Otp);

public record ResetPasswordRequest(string PhoneNumber, string Otp, string NewPassword);

public interface IAuthService
{
    Task RegisterAsync(RegisterRequest request);
    /// <summary>Register a victim with phone + PIN (no OTP step).</summary>
    Task<TokenResponse> RegisterWithPinAsync(RegisterWithPinRequest request);
    Task<TokenResponse> VerifyOtpAsync(OtpVerifyRequest request);
    Task<TokenResponse> LoginAsync(LoginRequest request);
    Task<TokenResponse> RefreshTokenAsync(string refreshToken);
    Task LogoutAsync(string refreshToken);
    Task RequestOtpAsync(string phoneNumber);
    Task ResetPasswordAsync(ResetPasswordRequest request);
    Task<User?> GetUserByIdAsync(Guid userId);
}
