using Microsoft.EntityFrameworkCore;
using SafeVoice.Core.Entities;
using SafeVoice.Core.Interfaces;
using SafeVoice.Infrastructure.Data;

namespace SafeVoice.Infrastructure.Services;

public class CaseService : ICaseService
{
    private readonly AppDbContext _db;
    private readonly IAuditLogService _audit;
    private readonly INotificationService _notification;
    private readonly IAiService _ai;

    public CaseService(AppDbContext db, IAuditLogService audit, INotificationService notification, IAiService ai)
    {
        _db = db;
        _audit = audit;
        _notification = notification;
        _ai = ai;
    }

    public async Task<CaseResponse> SubmitCaseAsync(SubmitCaseRequest request)
    {
        var caseEntity = BuildCase(request);
        _db.Cases.Add(caseEntity);
        await _db.SaveChangesAsync();

        await _audit.LogAsync(AuditEventTypes.ReportSubmitted, request.UserId,
            new { caseId = caseEntity.Id, incidentType = request.IncidentType });

        // Trigger AI risk assessment asynchronously (fire-and-forget with timeout)
        _ = Task.Run(() => RunAiAssessmentAsync(caseEntity));

        return MapToResponse(caseEntity);
    }

    public async Task<CaseResponse> SubmitAnonymousCaseAsync(SubmitCaseRequest request)
    {
        var caseEntity = BuildCase(request);
        // P5: unique anonymous case ID, not linked to any user
        caseEntity.IsAnonymous = true;
        caseEntity.UserId = null;
        caseEntity.AnonymousCaseId = GenerateAnonymousCaseId();

        _db.Cases.Add(caseEntity);
        await _db.SaveChangesAsync();

        _ = Task.Run(() => RunAiAssessmentAsync(caseEntity));

        return MapToResponse(caseEntity);
    }

    public async Task<List<CaseResponse>> GetUserCasesAsync(Guid userId)
    {
        // P21: sorted by submittedAt descending
        var cases = await _db.Cases
            .Include(c => c.StatusHistory)
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.SubmittedAt)
            .ToListAsync();

        return cases.Select(MapToResponse).ToList();
    }

    public async Task<CaseResponse?> GetCaseByIdAsync(Guid caseId, Guid? requestingUserId)
    {
        var c = await _db.Cases
            .Include(c => c.StatusHistory)
            .FirstOrDefaultAsync(c => c.Id == caseId);

        if (c == null) return null;

        // RBAC: victims can only see their own cases
        if (requestingUserId.HasValue && c.UserId != requestingUserId && !c.IsAnonymous)
            return null;

        return MapToResponse(c);
    }

    public async Task<CaseResponse> UpdateStatusAsync(Guid caseId, CaseStatus newStatus, string changedBy, string? reason = null)
    {
        var c = await _db.Cases.Include(c => c.StatusHistory)
            .FirstOrDefaultAsync(c => c.Id == caseId)
            ?? throw new InvalidOperationException("CASE_NOT_FOUND");

        var history = new CaseStatusHistory
        {
            CaseId = c.Id,
            OldStatus = c.Status.ToString(),
            NewStatus = newStatus.ToString(),
            ChangedBy = changedBy,
            Reason = reason,
        };
        _db.CaseStatusHistories.Add(history);

        c.Status = newStatus;
        c.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        if (c.UserId.HasValue)
            await _notification.SendCaseStatusUpdateAsync(c.UserId.Value, c.Id.ToString(), newStatus.ToString());

        await _audit.LogAsync("CASE_STATUS_CHANGED", Guid.TryParse(changedBy, out var aid) ? aid : (Guid?)null,
            new { caseId, oldStatus = history.OldStatus, newStatus = newStatus.ToString(), reason });

        return MapToResponse(c);
    }

    private async Task RunAiAssessmentAsync(Case caseEntity)
    {
        try
        {
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
            var result = await _ai.AssessRiskAsync(
                new AiAssessRequest(caseEntity.Id.ToString(), caseEntity.Description, "en"), cts.Token);

            if (result == null)
            {
                await SetDefaultRiskAsync(caseEntity.Id);
                return;
            }

            // P25: risk level must be Low/Medium/High
            if (!Enum.TryParse<RiskLevel>(result.RiskLevel, ignoreCase: true, out var risk))
                risk = RiskLevel.Medium;

            caseEntity.RiskLevel = risk;

            if (result.PotentialDuplicateCaseIds.Count > 0)
                caseEntity.IsDuplicateFlagged = true;

            await _db.SaveChangesAsync();

            // P26 inverse: escalate if High risk
            if (risk == RiskLevel.High && caseEntity.District != null)
                await _notification.SendSmsAsync(
                    GetDutyOfficerPhone(caseEntity.District),
                    $"HIGH RISK CASE: {caseEntity.Id} in district {caseEntity.District}. Immediate attention required.");
        }
        catch
        {
            await SetDefaultRiskAsync(caseEntity.Id);
        }
    }

    private async Task SetDefaultRiskAsync(Guid caseId)
    {
        // P26: AI unavailable → default Medium + audit log
        var c = await _db.Cases.FindAsync(caseId);
        if (c != null)
        {
            c.RiskLevel = RiskLevel.Medium;
            await _db.SaveChangesAsync();
        }
        await _audit.LogAsync(AuditEventTypes.AiServiceUnavailable, null, new { caseId });
    }

    private static Case BuildCase(SubmitCaseRequest r) => new()
    {
        UserId = r.UserId,
        IncidentType = r.IncidentType,
        Description = r.Description,
        IncidentDate = DateTime.SpecifyKind(r.IncidentDate, DateTimeKind.Utc),
        LocationText = r.LocationText,
        Latitude = r.Latitude,
        Longitude = r.Longitude,
        IsAnonymous = r.IsAnonymous,
    };

    private static string GenerateAnonymousCaseId() =>
        "ANON-" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();

    private static string GetDutyOfficerPhone(string district) =>
        "+251911000000"; // TODO: look up from Districts table

    private static CaseResponse MapToResponse(Case c) => new(
        c.Id,
        c.AnonymousCaseId,
        c.IncidentType,
        c.Description,
        c.IncidentDate,
        c.Status,
        c.RiskLevel,
        c.District,
        c.IsAnonymous,
        c.SubmittedAt,
        c.StatusHistory.Select(h => new StatusHistoryEntry(h.OldStatus, h.NewStatus, h.ChangedAt)).ToList());
}
