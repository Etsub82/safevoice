using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;
using BCrypt.Net;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "InstitutionalAdmin,SystemAdmin,Admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IAuditLogService _audit;

    public AdminController(AppDbContext db, IAuditLogService audit)
    {
        _db = db;
        _audit = audit;
    }

    // ── Users ────────────────────────────────────────────────────────────────

    [HttpGet("users")]
    public async Task<IActionResult> ListUsers([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        pageSize = Math.Clamp(pageSize, 1, 200);
        var total = await _db.Users.CountAsync();
        var items = await _db.Users
            .OrderBy(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                u.Id,
                Username = u.Username ?? u.PhoneNumber,
                Role = u.Role.ToString(),
                u.Organization,
                u.Jurisdiction,
                u.IsActive,
                u.CreatedAt,
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpPost("users")]
    public async Task<IActionResult> CreateUser([FromBody] CreatePortalUserDto dto)
    {
        if (!Enum.TryParse<UserRole>(dto.Role, ignoreCase: true, out var role))
            return BadRequest(new { error = "INVALID_ROLE" });

        var exists = await _db.Users.AnyAsync(u => u.Username == dto.Username);
        if (exists) return Conflict(new { error = "USERNAME_IN_USE" });

        var user = new User
        {
            Username = dto.Username,
            PhoneNumber = dto.PhoneNumber ?? string.Empty,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Role = role,
            Organization = dto.Organization,
            Jurisdiction = dto.Jurisdiction,
            IsActive = true,
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        var actorId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await _audit.LogAsync("ADMIN_USER_MODIFIED", actorId,
            new { action = "CREATE", targetUserId = user.Id },
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return CreatedAtAction(nameof(ListUsers), new { }, new
        {
            user.Id,
            user.Username,
            Role = user.Role.ToString(),
            user.Organization,
            user.Jurisdiction,
            user.IsActive,
            user.CreatedAt,
        });
    }

    [HttpPatch("users/{id:guid}")]
    public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdatePortalUserDto dto)
    {
        var user = await _db.Users.FindAsync(id);
        if (user == null) return NotFound(new { error = "USER_NOT_FOUND" });

        if (dto.Role != null && Enum.TryParse<UserRole>(dto.Role, ignoreCase: true, out var role))
            user.Role = role;
        if (dto.Organization != null) user.Organization = dto.Organization;
        if (dto.Jurisdiction != null) user.Jurisdiction = dto.Jurisdiction;
        if (dto.IsActive.HasValue) user.IsActive = dto.IsActive.Value;

        await _db.SaveChangesAsync();

        var actorId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        await _audit.LogAsync("ADMIN_USER_MODIFIED", actorId,
            new { action = "UPDATE", targetUserId = id },
            HttpContext.Connection.RemoteIpAddress?.ToString());

        return Ok(new { success = true });
    }

    // ── Organizations ─────────────────────────────────────────────────────────

    [HttpGet("organizations")]
    public async Task<IActionResult> ListOrganizations()
    {
        // Return distinct organizations from the users table
        var orgs = await _db.Users
            .Where(u => u.Organization != null)
            .GroupBy(u => new { u.Organization, u.Jurisdiction })
            .Select(g => new
            {
                Id = g.Key.Organization,
                Name = g.Key.Organization,
                Jurisdiction = g.Key.Jurisdiction,
            })
            .Distinct()
            .ToListAsync();

        return Ok(orgs);
    }
}

public record CreatePortalUserDto(
    string Username,
    string Password,
    string Role,
    string Organization,
    string Jurisdiction,
    string? PhoneNumber);

public record UpdatePortalUserDto(
    string? Role,
    string? Organization,
    string? Jurisdiction,
    bool? IsActive);
