namespace SafeVoice.Core.Interfaces;

public record AiAssessRequest(string CaseId, string ReportText, string Language);

public record AiAssessResponse(string RiskLevel, List<string> PotentialDuplicateCaseIds);

public record TranscribeRequest(string AudioUrl, string Language);

public record TranscribeResponse(string Transcript, bool Success);

public interface IAiService
{
    Task<AiAssessResponse?> AssessRiskAsync(AiAssessRequest request, CancellationToken ct = default);
    Task<TranscribeResponse?> TranscribeAudioAsync(TranscribeRequest request, CancellationToken ct = default);
    Task<string?> TranslateAsync(string text, string targetLanguage, CancellationToken ct = default);
}
