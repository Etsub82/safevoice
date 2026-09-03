namespace SafeVoice.Core.Entities;

public enum CaseStatus
{
    Submitted,
    Received,
    Triaged,
    Assigned,
    Investigation,
    Escalated,
    Reassigned,
    ReferredToJustice,
    CourtProcess,
    Resolved,
    Closed,
    // Legacy aliases kept for backward compat with mobile app
    UnderReview,
    InvestigationInProgress
}

public enum RiskLevel { Low, Medium, High }

public class Case
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? UserId { get; set; }
    public User? User { get; set; }
    public string? AnonymousCaseId { get; set; }
    public string IncidentType { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime IncidentDate { get; set; }
    public string? LocationText { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    public CaseStatus Status { get; set; } = CaseStatus.Submitted;
    public string? District { get; set; }
    public RiskLevel RiskLevel { get; set; } = RiskLevel.Medium;
    public bool IsAnonymous { get; set; } = false;
    public bool IsDuplicateFlagged { get; set; } = false;
    public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Assignment
    public Guid? AssignedOfficerId { get; set; }
    public User? AssignedOfficer { get; set; }
    public DateTime? AssignedAt { get; set; }
    public Guid? AssignedByHeadId { get; set; }

    // Department referral
    public string? ReferredToDepartment { get; set; }
    public string? ReferralReason { get; set; }
    public DateTime? ReferredAt { get; set; }

    public ICollection<CaseStatusHistory> StatusHistory { get; set; } = new List<CaseStatusHistory>();
    public ICollection<Evidence> Evidence { get; set; } = new List<Evidence>();
    public ICollection<LocationPing> LocationPings { get; set; } = new List<LocationPing>();
    public ICollection<InvestigationNote> InvestigationNotes { get; set; } = new List<InvestigationNote>();
}
