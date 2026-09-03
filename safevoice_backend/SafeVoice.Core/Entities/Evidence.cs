namespace SafeVoice.Core.Entities;

public class Evidence
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CaseId { get; set; }
    public Case Case { get; set; } = null!;
    public string FileName { get; set; } = string.Empty;
    public string MimeType { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public string StorageUrl { get; set; } = string.Empty;
    public string? LocalPath { get; set; }   // Dev/demo: local file path for download
    public bool VirusScanPassed { get; set; } = false;
    public bool UploadConfirmed { get; set; } = false;
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
}
