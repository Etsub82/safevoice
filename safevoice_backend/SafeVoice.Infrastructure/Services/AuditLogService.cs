using System.Text.Json;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.Infrastructure.Services;

public class AuditLogService : IAuditLogService
{
    private readonly AppDbContext _db;

    public AuditLogService(AppDbContext db) => _db = db;

    public async Task LogAsync(string eventType, Guid? userId = null, object? metadata = null, string? ipAddress = null)
    {
        var entry = new AuditLog
        {
            EventType = eventType,
            UserId = userId,
            EventMetadata = metadata != null ? JsonSerializer.Serialize(metadata) : null,
            IpAddress = ipAddress,
        };
        _db.AuditLogs.Add(entry);
        await _db.SaveChangesAsync();
    }
}
