using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/users/me/emergency-contacts")]
[Authorize]
public class EmergencyContactsController : ControllerBase
{
    private readonly AppDbContext _db;
    private const int MaxContacts = 5;

    public EmergencyContactsController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var contacts = await _db.EmergencyContacts
            .Where(e => e.UserId == userId)
            .Select(e => new { e.Id, e.Name, e.PhoneNumber })
            .ToListAsync();
        return Ok(contacts);
    }

    [HttpPost]
    public async Task<IActionResult> Add([FromBody] EmergencyContactDto dto)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var count = await _db.EmergencyContacts.CountAsync(e => e.UserId == userId);
        if (count >= MaxContacts)
            return BadRequest(new { error = "MAX_CONTACTS_REACHED" });

        var contact = new EmergencyContact
        {
            UserId = userId,
            Name = dto.Name,
            PhoneNumber = dto.PhoneNumber,
        };
        _db.EmergencyContacts.Add(contact);
        await _db.SaveChangesAsync();
        return Ok(new { contact.Id, contact.Name, contact.PhoneNumber });
    }

    [HttpDelete("{contactId:guid}")]
    public async Task<IActionResult> Remove(Guid contactId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var contact = await _db.EmergencyContacts
            .FirstOrDefaultAsync(e => e.Id == contactId && e.UserId == userId);

        if (contact == null) return NotFound(new { error = "NOT_FOUND" });

        _db.EmergencyContacts.Remove(contact);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}

public record EmergencyContactDto(string Name, string PhoneNumber);
