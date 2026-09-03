using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/audit-logs")]
[Authorize(Roles = "SystemAdmin,SecurityAuditor,FederalAuthority,Admin")]
public class AuditLogsController : ControllerBase
{
    private readonly AppDbContext _db;

    public AuditLogsController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<IActionResult> GetLogs(
        [FromQuery] string? eventType,
        [FromQuery] Guid? userId,
        [FromQuery] Guid? caseId,
        [FromQuery] DateTime? dateFrom,
        [FromQuery] DateTime? dateTo,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        pageSize = Math.Clamp(pageSize, 1, 200);

        var query = _db.AuditLogs.AsQueryable();

        if (!string.IsNullOrWhiteSpace(eventType))
            query = query.Where(a => a.EventType == eventType);
        if (userId.HasValue)
            query = query.Where(a => a.UserId == userId);
        if (caseId.HasValue)
            query = query.Where(a => EF.Functions.JsonContains(a.EventMetadata, $"{{\"caseId\":\"{caseId}\"}}"));
        if (dateFrom.HasValue)
            query = query.Where(a => a.OccurredAt >= dateFrom.Value);
        if (dateTo.HasValue)
            query = query.Where(a => a.OccurredAt <= dateTo.Value);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(a => a.OccurredAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new
            {
                a.Id,
                a.EventType,
                UserId = a.UserId != null ? a.UserId.ToString() : null,
                UserRole = a.User != null ? a.User.Role.ToString() : null,
                a.IpAddress,
                a.OccurredAt,
                a.EventMetadata,
            })
            .ToListAsync();

        return Ok(new { items, total, page, pageSize });
    }
}
