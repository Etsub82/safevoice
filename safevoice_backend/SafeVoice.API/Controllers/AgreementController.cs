using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/agreement")]
[Authorize]
public class AgreementController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IAuditLogService _audit;

    public AgreementController(AppDbContext db, IAuditLogService audit)
    {
        _db = db;
        _audit = audit;
    }

    [HttpGet("status")]
    public async Task<IActionResult> GetStatus()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();
        return Ok(new { agreementAccepted = user.AgreementAccepted, acceptedAt = user.AgreementAcceptedAt });
    }

    [HttpPost("accept")]
    public async Task<IActionResult> Accept()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        user.AgreementAccepted = true;
        user.AgreementAcceptedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        await _audit.LogAsync("AGREEMENT_ACCEPTED", userId, new { userId = userId.ToString() });
        return Ok(new { message = "Agreement accepted." });
    }

    [HttpPost("reject")]
    public async Task<IActionResult> Reject()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        user.AgreementAccepted = false;
        await _db.SaveChangesAsync();

        await _audit.LogAsync("AGREEMENT_REJECTED", userId, new { userId = userId.ToString() });
        return Ok(new { message = "Agreement rejected. Access denied." });
    }
}
