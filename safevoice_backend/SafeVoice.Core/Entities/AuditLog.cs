namespace SafeVoice.Core.Entities;

public class AuditLog
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? UserId { get; set; }
    public User? User { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string? EventMetadata { get; set; } // JSON string
    public string? IpAddress { get; set; }
    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
}

public static class AuditEventTypes
{
    public const string Login = "LOGIN";
    public const string Logout = "LOGOUT";
    public const string Register = "REGISTER";
    public const string ReportSubmitted = "REPORT_SUBMITTED";
    public const string EvidenceUploaded = "EVIDENCE_UPLOADED";
    public const string SosActivated = "SOS_ACTIVATED";
    public const string AccountModified = "ACCOUNT_MODIFIED";
    public const string AiServiceUnavailable = "AI_SERVICE_UNAVAILABLE";
    public const string OtpRequested = "OTP_REQUESTED";
    public const string PasswordReset = "PASSWORD_RESET";
    public const string AccountLocked = "ACCOUNT_LOCKED";
}
