namespace SafeVoice.Core.Entities;

public class DeviceToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string FcmToken { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty; // "android" | "ios"
    public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
    public DateTime LastSeen { get; set; } = DateTime.UtcNow;
}
