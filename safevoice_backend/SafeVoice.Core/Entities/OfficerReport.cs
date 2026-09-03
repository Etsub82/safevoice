namespace SafeVoice.Core.Entities;

public class OfficerReport
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CaseId { get; set; }
    public Case Case { get; set; } = null!;
    public Guid OfficerId { get; set; }
    public User Officer { get; set; } = null!;
    public string ActionsTaken { get; set; } = string.Empty;
    public string Findings { get; set; } = string.Empty;
    public string? Blockers { get; set; }
    public string? RecommendedNextAction { get; set; }
    public bool RequiresAnotherDepartment { get; set; } = false;
    public string? TargetDepartment { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool ReviewedByHead { get; set; } = false;
    public DateTime? ReviewedAt { get; set; }
}
