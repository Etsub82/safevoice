namespace SafeVoice.Core.Interfaces;

public interface INotificationService
{
    Task SendPushAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null);
    Task SendSmsAsync(string phoneNumber, string message);
    Task SendSosAlertsAsync(Guid userId, string caseId, decimal? latitude, decimal? longitude);
    Task RegisterDeviceTokenAsync(Guid userId, string fcmToken, string platform);
    Task SendCaseStatusUpdateAsync(Guid userId, string caseId, string newStatus);
}
