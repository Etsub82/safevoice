using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/sos")]
[Authorize]
public class SosController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly INotificationService _notification;
    private readonly IAuditLogService _audit;

    public SosController(AppDbContext db, INotificationService notification, IAuditLogService audit)
    {
        _db = db;
        _notification = notification;
        _audit = audit;
    }

    /// <summary>Trigger SOS alert. Implements Req 6.3, 6.4, 6.8.</summary>
    [HttpPost]
    public async Task<IActionResult> TriggerSos([FromBody] SosRequest request)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Create high-priority case record within 5 seconds
        var sosCase = new Case
        {
            UserId = userId,
            IncidentType = "SOS Emergency",
            Description = "SOS emergency alert triggered by victim.",
            IncidentDate = DateTime.UtcNow,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Status = CaseStatus.Submitted,
            RiskLevel = RiskLevel.High,
        };

        _db.Cases.Add(sosCase);
        await _db.SaveChangesAsync();

        // Dispatch SMS + push to all emergency contacts
        await _notification.SendSosAlertsAsync(
            userId,
            sosCase.Id.ToString(),
            request.Latitude,
            request.Longitude);

        await _audit.LogAsync(AuditEventTypes.SosActivated, userId,
            new { caseId = sosCase.Id, latitude = request.Latitude, longitude = request.Longitude });

        return CreatedAtAction(null, null, new { sosId = sosCase.Id });
    }

    /// <summary>Cancel SOS within countdown window. Implements Req 6.6.</summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> CancelSos(Guid id)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var sosCase = await _db.Cases.FindAsync(id);

        if (sosCase == null || sosCase.UserId != userId)
            return NotFound(new { error = "NOT_FOUND" });

        // Only cancellable if submitted within last 15 seconds
        if ((DateTime.UtcNow - sosCase.SubmittedAt).TotalSeconds > 15)
            return BadRequest(new { error = "CANCEL_WINDOW_EXPIRED" });

        _db.Cases.Remove(sosCase);
        await _db.SaveChangesAsync();

        return Ok(new { message = "SOS cancelled." });
    }
}

public record SosRequest(decimal? Latitude, decimal? Longitude);
