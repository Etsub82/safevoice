using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _config;
    private static readonly HttpClient _httpClient = new();

    public NotificationService(AppDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    public async Task SendPushAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null)
    {
        var tokens = await _db.DeviceTokens
            .Where(d => d.UserId == userId)
            .Select(d => d.FcmToken)
            .ToListAsync();

        foreach (var token in tokens)
        {
            Console.WriteLine($"[FCM] Sending to {token[..10]}...: {title}");
        }
    }

    public async Task SendSmsAsync(string phoneNumber, string message)
    {
        var apiKey = _config["AfricasTalking:ApiKey"];
        var username = _config["AfricasTalking:Username"];

        // If not configured, just log
        if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(username) 
            || apiKey == "YOUR_AFRICASTALKING_API_KEY")
        {
            Console.WriteLine($"[SMS] To {phoneNumber}: {message}");
            return;
        }

        // Format phone number — must be international format e.g. +251982496641
        var formattedPhone = FormatEthiopianPhone(phoneNumber);

        // Use sandbox URL for sandbox username, production for others
        var smsUrl = username == "sandbox"
            ? "https://api.sandbox.africastalking.com/version1/messaging"
            : "https://api.africastalking.com/version1/messaging";

        try
        {
            // Create fresh request to avoid header conflicts
            var request = new HttpRequestMessage(HttpMethod.Post, smsUrl);
            request.Headers.Add("apiKey", apiKey);
            request.Headers.Add("Accept", "application/json");
            request.Content = new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("username", username),
                new KeyValuePair<string, string>("to", formattedPhone),
                new KeyValuePair<string, string>("message", message),
            });

            var response = await _httpClient.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
                Console.WriteLine($"[SMS] Sent to {formattedPhone}: {responseBody}");
            else
                Console.WriteLine($"[SMS] Failed to {formattedPhone}: {response.StatusCode} - {responseBody}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SMS] Error sending to {formattedPhone}: {ex.Message}");
        }
    }

    /// Converts Ethiopian phone numbers to international format (+251...)
    private static string FormatEthiopianPhone(string phone)
    {
        phone = phone.Trim().Replace(" ", "").Replace("-", "");
        if (phone.StartsWith("+")) return phone;
        if (phone.StartsWith("251")) return "+" + phone;
        if (phone.StartsWith("0")) return "+251" + phone[1..];
        return "+251" + phone;
    }

    public async Task SendSosAlertsAsync(Guid userId, string caseId, decimal? latitude, decimal? longitude)
    {
        var contacts = await _db.EmergencyContacts
            .Where(e => e.UserId == userId)
            .ToListAsync();

        var locationText = latitude.HasValue
            ? $"Location: https://maps.google.com/?q={latitude},{longitude}"
            : "Location not available";

        var message = $"EMERGENCY ALERT from SafeVoice. Case #{caseId[..8]}. {locationText}";

        foreach (var contact in contacts)
            await SendSmsAsync(contact.PhoneNumber, message);

        await SendPushAsync(userId, "SOS Sent", "Your emergency alert has been dispatched.",
            new Dictionary<string, string> { ["event_type"] = "SOS_SENT", ["case_id"] = caseId });
    }

    public async Task RegisterDeviceTokenAsync(Guid userId, string fcmToken, string platform)
    {
        var existing = await _db.DeviceTokens
            .FirstOrDefaultAsync(d => d.UserId == userId && d.FcmToken == fcmToken);

        if (existing != null)
        {
            existing.LastSeen = DateTime.UtcNow;
        }
        else
        {
            _db.DeviceTokens.Add(new Core.Entities.DeviceToken
            {
                UserId = userId,
                FcmToken = fcmToken,
                Platform = platform,
            });
        }
        await _db.SaveChangesAsync();
    }

    public async Task SendCaseStatusUpdateAsync(Guid userId, string caseId, string newStatus)
    {
        var user = await _db.Users.FindAsync(userId);
        var data = new Dictionary<string, string>
        {
            ["event_type"] = "CASE_STATUS_CHANGED",
            ["case_id"] = caseId,
            ["new_status"] = newStatus,
            ["deep_link"] = $"/cases/{caseId}",
        };

        bool fcmSent = false;
        try
        {
            await SendPushAsync(userId, "Case Update", $"Your case status changed to {newStatus}", data);
            fcmSent = true;
        }
        catch { /* FCM failed */ }

        // SMS fallback if FCM fails
        if (!fcmSent && user != null)
            await SendSmsAsync(user.PhoneNumber, $"SafeVoice: Case #{caseId[..8]} status → {newStatus}");
    }
}
