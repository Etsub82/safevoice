namespace SafeVoice.Core.Interfaces;

public interface IAuditLogService
{
    Task LogAsync(string eventType, Guid? userId = null, object? metadata = null, string? ipAddress = null);
}
