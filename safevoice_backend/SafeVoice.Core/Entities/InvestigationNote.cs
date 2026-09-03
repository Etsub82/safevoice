namespace SafeVoice.Core.Entities;

public class InvestigationNote
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CaseId { get; set; }
    public Guid AuthorId { get; set; }
    public string AuthorName { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Case Case { get; set; } = null!;
    public User Author { get; set; } = null!;
}
