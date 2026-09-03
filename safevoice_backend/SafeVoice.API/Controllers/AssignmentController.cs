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
[Authorize]
public class AssignmentController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IAuditLogService _audit;

    public AssignmentController(AppDbContext db, IAuditLogService audit)
    {
        _db = db;
        _audit = audit;
    }

    // HEAD OF DEPARTMENT: Assign case to officer
    [HttpPatch("{id:guid}/assign")]
    [Authorize(Roles = "HeadOfDepartment,Supervisor,InstitutionalAdmin,SystemAdmin,Admin")]
    public async Task<IActionResult> AssignCase(Guid id, [FromBody] AssignCaseDto dto)
    {
        var headId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var c = await _db.Cases.FindAsync(id);
        if (c == null) return NotFound(new { error = "NOT_FOUND" });

        var officer = await _db.Users.FindAsync(dto.OfficerId);
        if (officer == null) return BadRequest(new { error = "OFFICER_NOT_FOUND" });

        c.AssignedOfficerId = dto.OfficerId;
        c.AssignedByHeadId = headId;
        c.AssignedAt = DateTime.UtcNow;
        c.Status = CaseStatus.Assigned;
        c.UpdatedAt = DateTime.UtcNow;

        // Add status history
        _db.CaseStatusHistories.Add(new CaseStatusHistory
        {
            CaseId = c.Id,
            OldStatus = c.Status.ToString(),
            NewStatus = CaseStatus.Assigned.ToString(),
            ChangedBy = headId.ToString(),
            Reason = dto.Reason ?? $"Assigned to {officer.Username ?? officer.DisplayName}",
        });

        await _db.SaveChangesAsync();
        await _audit.LogAsync("CASE_ASSIGNMENT_CHANGED", headId,
            new { caseId = id, officerId = dto.OfficerId, officerName = officer.Username });

        return Ok(new { message = "Case assigned.", assignedOfficerName = officer.Username ?? officer.DisplayName });
    }

    // HEAD OF DEPARTMENT: Get department stats
    [HttpGet("department/stats")]
    [Authorize(Roles = "HeadOfDepartment,Supervisor,InstitutionalAdmin,SystemAdmin,Admin")]
    public async Task<IActionResult> GetDepartmentStats()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var user = await _db.Users.FindAsync(userId);

        var query = _db.Cases.AsQueryable();

        var total = await query.CountAsync();
        var unassigned = await query.CountAsync(c => c.AssignedOfficerId == null && c.Status == CaseStatus.Submitted);
        var assigned = await query.CountAsync(c => c.AssignedOfficerId != null && c.Status == CaseStatus.Assigned);
        var inProgress = await query.CountAsync(c => c.Status == CaseStatus.Investigation);
        var highRisk = await query.CountAsync(c => c.RiskLevel == RiskLevel.High);
        var resolved = await query.CountAsync(c => c.Status == CaseStatus.Resolved || c.Status == CaseStatus.Closed);

        // Cases per officer
        var perOfficer = await query
            .Where(c => c.AssignedOfficerId != null)
            .GroupBy(c => c.AssignedOfficerId)
            .Select(g => new { OfficerId = g.Key, Count = g.Count() })
            .ToListAsync();

        var officerIds = perOfficer.Select(p => p.OfficerId!.Value).ToList();
        var officers = await _db.Users
            .Where(u => officerIds.Contains(u.Id))
            .Select(u => new { u.Id, u.Username, u.DisplayName })
            .ToListAsync();

        var perOfficerNamed = perOfficer.Select(p =>
        {
            var o = officers.FirstOrDefault(x => x.Id == p.OfficerId);
            return new { officerId = p.OfficerId, name = o?.Username ?? o?.DisplayName ?? "Unknown", count = p.Count };
        }).ToList();

        return Ok(new { total, unassigned, assigned, inProgress, highRisk, resolved, perOfficer = perOfficerNamed });
    }

    // OFFICER: Submit report to Head
    [HttpPost("{id:guid}/reports")]
    [Authorize(Roles = "Officer,Investigator,HeadOfDepartment,Supervisor")]
    public async Task<IActionResult> SubmitReport(Guid id, [FromBody] OfficerReportDto dto)
    {
        var officerId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var c = await _db.Cases.FindAsync(id);
        if (c == null) return NotFound(new { error = "NOT_FOUND" });

        var report = new OfficerReport
        {
            CaseId = id,
            OfficerId = officerId,
            ActionsTaken = dto.ActionsTaken,
            Findings = dto.Findings,
            Blockers = dto.Blockers,
            RecommendedNextAction = dto.RecommendedNextAction,
            RequiresAnotherDepartment = dto.RequiresAnotherDepartment,
            TargetDepartment = dto.TargetDepartment,
        };

        _db.OfficerReports.Add(report);

        if (dto.RequiresAnotherDepartment && !string.IsNullOrWhiteSpace(dto.TargetDepartment))
        {
            c.ReferredToDepartment = dto.TargetDepartment;
            c.ReferralReason = dto.Findings;
            c.ReferredAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync();
        await _audit.LogAsync("OFFICER_REPORT_SUBMITTED", officerId,
            new { caseId = id, requiresAnotherDept = dto.RequiresAnotherDepartment });

        return Ok(new { message = "Report submitted.", reportId = report.Id });
    }

    // HEAD: Get reports for a case
    [HttpGet("{id:guid}/reports")]
    [Authorize(Roles = "HeadOfDepartment,Supervisor,InstitutionalAdmin,SystemAdmin,Admin,Officer,Investigator")]
    public async Task<IActionResult> GetReports(Guid id)
    {
        var reports = await _db.OfficerReports
            .Where(r => r.CaseId == id)
            .Include(r => r.Officer)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new
            {
                r.Id,
                r.CaseId,
                r.OfficerId,
                OfficerName = r.Officer.Username ?? r.Officer.DisplayName,
                r.ActionsTaken,
                r.Findings,
                r.Blockers,
                r.RecommendedNextAction,
                r.RequiresAnotherDepartment,
                r.TargetDepartment,
                r.CreatedAt,
                r.ReviewedByHead,
                r.ReviewedAt,
            })
            .ToListAsync();

        return Ok(reports);
    }

    // HEAD: Mark report as reviewed
    [HttpPatch("{caseId:guid}/reports/{reportId:guid}/review")]
    [Authorize(Roles = "HeadOfDepartment,Supervisor,InstitutionalAdmin,SystemAdmin,Admin")]
    public async Task<IActionResult> ReviewReport(Guid caseId, Guid reportId)
    {
        var headId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var report = await _db.OfficerReports.FindAsync(reportId);
        if (report == null || report.CaseId != caseId) return NotFound();

        report.ReviewedByHead = true;
        report.ReviewedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        await _audit.LogAsync("OFFICER_REPORT_REVIEWED", headId, new { reportId, caseId });

        return Ok(new { message = "Report marked as reviewed." });
    }

    // GET list of officers for assignment dropdown
    [HttpGet("officers")]
    [Authorize(Roles = "HeadOfDepartment,Supervisor,InstitutionalAdmin,SystemAdmin,Admin")]
    public async Task<IActionResult> GetOfficers()
    {
        var officers = await _db.Users
            .Where(u => u.Role == UserRole.Officer || u.Role == UserRole.Investigator)
            .Select(u => new { u.Id, u.Username, u.DisplayName, u.Organization, u.Jurisdiction })
            .ToListAsync();
        return Ok(officers);
    }
}

public record AssignCaseDto(Guid OfficerId, string? Reason);
public record OfficerReportDto(
    string ActionsTaken,
    string Findings,
    string? Blockers,
    string? RecommendedNextAction,
    bool RequiresAnotherDepartment,
    string? TargetDepartment);
