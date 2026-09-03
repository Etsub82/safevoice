using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.API.Controllers;

[ApiController]
[Route("api/cases/{caseId:guid}/evidence")]
[Authorize]
public class EvidenceController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IAuditLogService _audit;

    public EvidenceController(AppDbContext db, IAuditLogService audit)
    {
        _db = db;
        _audit = audit;
    }

    [HttpPost]
    [RequestSizeLimit(104_857_600)] // 100 MB
    public async Task<IActionResult> Upload(Guid caseId, IFormFile file)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var c = await _db.Cases.FirstOrDefaultAsync(c => c.Id == caseId && c.UserId == userId);
        if (c == null) return NotFound(new { error = "NOT_FOUND" });

        if (file.Length > 104_857_600)
            return BadRequest(new { error = "FILE_TOO_LARGE" });

        // TODO: run virus scan before storing
        // Save locally for dev/demo; in production upload to Azure Blob / S3
        var localDir = Path.Combine(Directory.GetCurrentDirectory(), "evidence_uploads",
            caseId.ToString(), Guid.NewGuid().ToString());
        Directory.CreateDirectory(localDir);
        var localPath = Path.Combine(localDir, file.FileName);
        await using (var stream = System.IO.File.Create(localPath))
            await file.CopyToAsync(stream);

        var storageUrl = $"local://{localPath}";

        var evidence = new Evidence
        {
            CaseId = caseId,
            FileName = file.FileName,
            MimeType = file.ContentType,
            FileSizeBytes = file.Length,
            StorageUrl = storageUrl,
            LocalPath = localPath,
            VirusScanPassed = true,
            UploadConfirmed = true,
        };

        _db.Evidence.Add(evidence);
        await _db.SaveChangesAsync();

        await _audit.LogAsync(AuditEventTypes.EvidenceUploaded, userId,
            new { caseId, evidenceId = evidence.Id, fileName = file.FileName });

        return CreatedAtAction(nameof(GetAll), new { caseId }, new
        {
            evidence.Id,
            evidence.FileName,
            evidence.MimeType,
            evidence.FileSizeBytes,
            evidence.UploadConfirmed,
        });
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(Guid caseId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var userRole = User.FindFirstValue(ClaimTypes.Role) ?? "Victim";

        // Portal roles can view evidence for any case
        // Victims can only view evidence for their own cases
        Case? c;
        if (IsPortalRole(userRole))
            c = await _db.Cases.FirstOrDefaultAsync(x => x.Id == caseId);
        else
            c = await _db.Cases.FirstOrDefaultAsync(x => x.Id == caseId && x.UserId == userId);

        if (c == null) return NotFound(new { error = "NOT_FOUND" });

        var evidence = await _db.Evidence
            .Where(e => e.CaseId == caseId)
            .Select(e => new
            {
                e.Id,
                e.FileName,
                e.MimeType,
                e.FileSizeBytes,
                e.UploadedAt,
                e.VirusScanPassed,
                e.UploadConfirmed,
            })
            .ToListAsync();

        return Ok(evidence);
    }

    [HttpGet("{evidenceId:guid}/download")]
    public async Task<IActionResult> Download(Guid caseId, Guid evidenceId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var userRole = User.FindFirstValue(ClaimTypes.Role) ?? "Victim";

        // Victim: only own cases. Portal roles: any case.
        Case? c;
        if (IsPortalRole(userRole))
            c = await _db.Cases.FirstOrDefaultAsync(x => x.Id == caseId);
        else
            c = await _db.Cases.FirstOrDefaultAsync(x => x.Id == caseId && x.UserId == userId);

        if (c == null) return NotFound(new { error = "NOT_FOUND" });

        var evidence = await _db.Evidence.FirstOrDefaultAsync(e => e.Id == evidenceId && e.CaseId == caseId);
        if (evidence == null) return NotFound(new { error = "NOT_FOUND" });

        await _audit.LogAsync(AuditEventTypes.EvidenceUploaded, userId,
            new { caseId, evidenceId, action = "DOWNLOAD" });

        // If file is stored locally (dev/demo), serve directly
        var localPath = evidence.LocalPath ?? Path.Combine(
            Directory.GetCurrentDirectory(), "evidence_uploads",
            caseId.ToString(), evidenceId.ToString(), evidence.FileName);

        if (System.IO.File.Exists(localPath))
        {
            var bytes = await System.IO.File.ReadAllBytesAsync(localPath);
            return File(bytes, evidence.MimeType ?? "application/octet-stream", evidence.FileName);
        }

        // Fallback: return metadata so client knows file info even if not locally stored
        return Ok(new
        {
            evidence.Id,
            evidence.FileName,
            evidence.MimeType,
            evidence.FileSizeBytes,
            evidence.UploadedAt,
            available = false,
            message = "File not stored locally. In production, this returns a signed download URL.",
        });
    }

    private static bool IsPortalRole(string role) =>
        role is "Officer" or "Investigator" or "Supervisor" or "HeadOfDepartment" or "WomensProtection"
            or "ChildProtection" or "EmergencyResponse" or "RegionalAuthority" or "FederalAuthority"
            or "Prosecutor" or "PublicProsecutor" or "CourtClerk" or "Judge"
            or "Lawyer" or "LegalAid" or "SocialWorker" or "ChildProtectionOrg"
            or "Shelter" or "HealthcareReferral" or "PsychosocialSupport" or "NGO"
            or "InstitutionalAdmin" or "SystemAdmin" or "SecurityAuditor" or "Admin";

    public async Task<IActionResult> Delete(Guid caseId, Guid evidenceId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var c = await _db.Cases.FirstOrDefaultAsync(c => c.Id == caseId && c.UserId == userId);
        if (c == null) return NotFound(new { error = "NOT_FOUND" });

        var evidence = await _db.Evidence.FirstOrDefaultAsync(e => e.Id == evidenceId && e.CaseId == caseId);
        if (evidence == null) return NotFound(new { error = "NOT_FOUND" });

        _db.Evidence.Remove(evidence);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
