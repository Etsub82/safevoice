using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/cases/{caseId:guid}/notes")]
[Authorize]
public class InvestigationNotesController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IAuditLogService _audit;

    public InvestigationNotesController(AppDbContext db, IAuditLogService audit)
    {
        _db = db;
        _audit = audit;
    }

    [HttpGet]
    public async Task<IActionResult> GetNotes(Guid caseId)
    {
        var notes = await _db.InvestigationNotes
            .Where(n => n.CaseId == caseId)
            .OrderBy(n => n.CreatedAt)
            .Select(n => new
            {
                n.Id,
                n.CaseId,
                n.AuthorId,
                n.AuthorName,
                n.Content,
                n.CreatedAt,
            })
            .ToListAsync();

        return Ok(notes);
    }

    [HttpPost]
    [Authorize(Roles = "Officer,Investigator,Supervisor,WomensProtection,ChildProtection,EmergencyResponse,RegionalAuthority,FederalAuthority,Prosecutor,PublicProsecutor,CourtClerk,Admin")]
    public async Task<IActionResult> AddNote(Guid caseId, [FromBody] AddNoteDto dto)
    {
        var authorId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var author = await _db.Users.FindAsync(authorId);
        if (author == null) return Unauthorized();

        var caseExists = await _db.Cases.AnyAsync(c => c.Id == caseId);
        if (!caseExists) return NotFound(new { error = "CASE_NOT_FOUND" });

        var note = new InvestigationNote
        {
            CaseId = caseId,
            AuthorId = authorId,
            AuthorName = author.DisplayName ?? author.Username ?? authorId.ToString(),
            Content = dto.Content,
        };

        _db.InvestigationNotes.Add(note);
        await _db.SaveChangesAsync();

        await _audit.LogAsync("INVESTIGATION_NOTE_ADDED", authorId,
            new { caseId, noteId = note.Id },
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return CreatedAtAction(nameof(GetNotes), new { caseId }, new
        {
            note.Id,
            note.CaseId,
            note.AuthorId,
            note.AuthorName,
            note.Content,
            note.CreatedAt,
        });
    }
}

public record AddNoteDto(string Content);
