using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/cases/{caseId:guid}/location")]
[Authorize]
public class LocationController : ControllerBase
{
    private readonly AppDbContext _db;

    public LocationController(AppDbContext db) => _db = db;

    /// <summary>Submit a location ping. Implements Req 7.2.</summary>
    [HttpPost]
    public async Task<IActionResult> AddPing(Guid caseId, [FromBody] LocationPingDto dto)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var c = await _db.Cases.FirstOrDefaultAsync(c => c.Id == caseId && c.UserId == userId);
        if (c == null) return NotFound(new { error = "NOT_FOUND" });

        var ping = new LocationPing
        {
            CaseId = caseId,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
        };
        _db.LocationPings.Add(ping);
        await _db.SaveChangesAsync();
        return Ok();
    }

    /// <summary>Stop live sharing — purge future pings. Implements Req 7.3, 7.5.</summary>
    [HttpDelete]
    public async Task<IActionResult> StopSharing(Guid caseId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var c = await _db.Cases.FirstOrDefaultAsync(c => c.Id == caseId && c.UserId == userId);
        if (c == null) return NotFound(new { error = "NOT_FOUND" });

        // Remove all pings for this case
        var pings = await _db.LocationPings.Where(p => p.CaseId == caseId).ToListAsync();
        _db.LocationPings.RemoveRange(pings);
        await _db.SaveChangesAsync();
        return Ok();
    }
}

public record LocationPingDto(decimal Latitude, decimal Longitude);
