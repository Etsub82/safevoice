using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/cases")]
public class CasesController : ControllerBase
{
    private readonly ICaseService _cases;
    private readonly AppDbContext _db;

    public CasesController(ICaseService cases, AppDbContext db)
    {
        _cases = cases;
        _db = db;
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Submit([FromBody] SubmitCaseDto dto)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await _cases.SubmitCaseAsync(new SubmitCaseRequest(
            userId, dto.IncidentType, dto.Description, dto.IncidentDate,
            dto.LocationText, dto.Latitude, dto.Longitude));
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpPost("anonymous")]
    public async Task<IActionResult> SubmitAnonymous([FromBody] SubmitCaseDto dto)
    {
        var result = await _cases.SubmitAnonymousCaseAsync(new SubmitCaseRequest(
            null, dto.IncidentType, dto.Description, dto.IncidentDate,
            dto.LocationText, dto.Latitude, dto.Longitude, IsAnonymous: true));
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpGet]
    [Authorize]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? status,
        [FromQuery] string? riskLevel,
        [FromQuery] string? incidentType,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var userRole = User.FindFirstValue(ClaimTypes.Role) ?? "Victim";
        pageSize = Math.Clamp(pageSize, 1, 200);

        // Portal roles see cases by jurisdiction; victim roles see only their own
        var isPortalRole = IsPortalRole(userRole);

        var query = _db.Cases.Include(c => c.StatusHistory).Include(c => c.AssignedOfficer).AsQueryable();

        if (!isPortalRole)
        {
            // Victims: only own cases
            query = query.Where(c => c.UserId == userId);
        }
        else if (userRole is "Officer" or "Investigator")
        {
            // Officers/Investigators: only cases assigned to them
            query = query.Where(c => c.AssignedOfficerId == userId);
        }
        // Supervisors, HeadOfDepartment, and above: all cases

        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<CaseStatus>(status, true, out var s))
            query = query.Where(c => c.Status == s);
        if (!string.IsNullOrWhiteSpace(riskLevel) && Enum.TryParse<RiskLevel>(riskLevel, true, out var r))
            query = query.Where(c => c.RiskLevel == r);
        if (!string.IsNullOrWhiteSpace(incidentType))
            query = query.Where(c => c.IncidentType == incidentType);
        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(c => c.Id.ToString().Contains(search) || c.IncidentType.Contains(search));

        var total = await query.CountAsync();
        var cases = await query
            .OrderByDescending(c => c.SubmittedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var items = cases.Select(c => MapToListItem(c, userRole)).ToList();
        return Ok(new { items, total, page, pageSize });
    }

    private static bool IsPortalRole(string role) =>
        role is "Officer" or "Investigator" or "Supervisor" or "HeadOfDepartment" or "WomensProtection" or "ChildProtection"
            or "EmergencyResponse" or "RegionalAuthority" or "FederalAuthority"
            or "Prosecutor" or "PublicProsecutor" or "CourtClerk" or "Judge"
            or "Lawyer" or "LegalAid" or "SocialWorker" or "ChildProtectionOrg"
            or "Shelter" or "HealthcareReferral" or "PsychosocialSupport" or "NGO"
            or "InstitutionalAdmin" or "SystemAdmin" or "SecurityAuditor" or "Admin";

    /// Returns Tier 1 fields only for authorized roles
    private static object MapToListItem(Case c, string role)
    {
        var hasTier1 = role is "Officer" or "Investigator" or "Supervisor" or "HeadOfDepartment" or "WomensProtection"
            or "ChildProtection" or "Prosecutor" or "PublicProsecutor" or "Judge"
            or "RegionalAuthority" or "FederalAuthority" or "Admin";

        return new
        {
            c.Id,
            c.IncidentType,
            c.Status,
            c.RiskLevel,
            c.District,
            c.SubmittedAt,
            c.IsAnonymous,
            AssignedOfficerName = c.AssignedOfficer != null ? (c.AssignedOfficer.Username ?? c.AssignedOfficer.DisplayName) : null,
            AssignedOfficerId = c.AssignedOfficerId,
            Description = (hasTier1 || role is "CourtClerk" or "Lawyer" or "LegalAid") ? c.Description : null,
        };
    }

    [HttpGet("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> GetById(Guid id)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var userRole = User.FindFirstValue(ClaimTypes.Role) ?? "Victim";
        var isPortal = IsPortalRole(userRole);

        // For portal users load full detail with notes; for victims use existing service
        if (isPortal)
        {
            var query = _db.Cases
                .Include(x => x.User)
                .Include(x => x.StatusHistory)
                .Include(x => x.InvestigationNotes)
                .Include(x => x.Evidence)
                .Include(x => x.AssignedOfficer)
                .Where(x => x.Id == id);

            // Officers/Investigators can only see their assigned cases
            if (userRole is "Officer" or "Investigator")
                query = query.Where(x => x.AssignedOfficerId == userId);

            var c = await query.FirstOrDefaultAsync();
            if (c == null) return NotFound(new { error = "NOT_FOUND" });

            var hasTier1 = userRole is "Officer" or "Investigator" or "Supervisor" or "HeadOfDepartment"
                or "WomensProtection" or "ChildProtection" or "Prosecutor"
                or "PublicProsecutor" or "Judge" or "RegionalAuthority" or "FederalAuthority" or "Admin";

            return Ok(new
            {
                c.Id,
                c.IncidentType,
                c.Description,
                c.Status,
                c.RiskLevel,
                c.District,
                c.SubmittedAt,
                c.UpdatedAt,
                c.IsAnonymous,
                AssignedOfficerId   = c.AssignedOfficerId,
                AssignedOfficerName = c.AssignedOfficer != null ? (c.AssignedOfficer.Username ?? c.AssignedOfficer.DisplayName) : null,
                AssignedAt          = c.AssignedAt,
                ReferredToDepartment = c.ReferredToDepartment,
                ReferralReason      = c.ReferralReason,
                // Tier 1 — only for authorized roles
                VictimContact = hasTier1 ? c.User?.PhoneNumber : null,
                VictimName    = hasTier1 ? c.User?.DisplayName : null,
                LocationText  = hasTier1 ? c.LocationText : null,
                Latitude      = hasTier1 ? c.Latitude : (decimal?)null,
                Longitude     = hasTier1 ? c.Longitude : (decimal?)null,
                StatusHistory = c.StatusHistory
                    .OrderBy(h => h.ChangedAt)
                    .Select(h => new { h.Id, h.OldStatus, h.NewStatus, h.ChangedBy, h.ChangedAt, h.Reason }),
                Notes = c.InvestigationNotes
                    .OrderBy(n => n.CreatedAt)
                    .Select(n => new { n.Id, n.CaseId, n.AuthorId, n.AuthorName, n.Content, n.CreatedAt }),
            });
        }

        // Victim path — only own cases
        var result = await _cases.GetCaseByIdAsync(id, userId);
        return result == null ? NotFound(new { error = "NOT_FOUND" }) : Ok(result);
    }

    [HttpPatch("{id:guid}/status")]
    [Authorize(Roles = "Officer,Investigator,Supervisor,HeadOfDepartment,WomensProtection,ChildProtection,EmergencyResponse,RegionalAuthority,FederalAuthority,Prosecutor,PublicProsecutor,CourtClerk,Admin")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateStatusDto dto)
    {
        if (!Enum.TryParse<CaseStatus>(dto.Status, ignoreCase: true, out var status))
            return BadRequest(new { error = "INVALID_STATUS" });

        var changedBy = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "unknown";
        var result = await _cases.UpdateStatusAsync(id, status, changedBy, dto.Reason);
        return Ok(result);
    }
}

public record SubmitCaseDto(
    string IncidentType,
    string Description,
    DateTime IncidentDate,
    string? LocationText,
    decimal? Latitude,
    decimal? Longitude);

public record UpdateStatusDto(string Status, string? Reason);
