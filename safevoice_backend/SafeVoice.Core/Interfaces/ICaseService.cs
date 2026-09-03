using SafeVoice.Core.Entities;

namespace SafeVoice.Core.Interfaces;

public record SubmitCaseRequest(
    Guid? UserId,
    string IncidentType,
    string Description,
    DateTime IncidentDate,
    string? LocationText,
    decimal? Latitude,
    decimal? Longitude,
    bool IsAnonymous = false);

public record CaseResponse(
    Guid Id,
    string? AnonymousCaseId,
    string IncidentType,
    string Description,
    DateTime IncidentDate,
    CaseStatus Status,
    RiskLevel RiskLevel,
    string? District,
    bool IsAnonymous,
    DateTime SubmittedAt,
    List<StatusHistoryEntry> StatusHistory);

public record StatusHistoryEntry(string OldStatus, string NewStatus, DateTime ChangedAt);

public interface ICaseService
{
    Task<CaseResponse> SubmitCaseAsync(SubmitCaseRequest request);
    Task<CaseResponse> SubmitAnonymousCaseAsync(SubmitCaseRequest request);
    Task<List<CaseResponse>> GetUserCasesAsync(Guid userId);
    Task<CaseResponse?> GetCaseByIdAsync(Guid caseId, Guid? requestingUserId);
    Task<CaseResponse> UpdateStatusAsync(Guid caseId, CaseStatus newStatus, string changedBy, string? reason = null);
}
