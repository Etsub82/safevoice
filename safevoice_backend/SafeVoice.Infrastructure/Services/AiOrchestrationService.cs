using System.Net.Http.Json;
using SafeVoice.Core.Interfaces;

namespace SafeVoice.Infrastructure.Services;

public class AiOrchestrationService : IAiService
{
    private readonly HttpClient _http;

    public AiOrchestrationService(HttpClient http) => _http = http;

    public async Task<AiAssessResponse?> AssessRiskAsync(AiAssessRequest request, CancellationToken ct = default)
    {
        var res = await _http.PostAsJsonAsync("/ai/assess", request, ct);
        res.EnsureSuccessStatusCode();
        return await res.Content.ReadFromJsonAsync<AiAssessResponse>(cancellationToken: ct);
    }

    public async Task<TranscribeResponse?> TranscribeAudioAsync(TranscribeRequest request, CancellationToken ct = default)
    {
        var res = await _http.PostAsJsonAsync("/ai/transcribe", request, ct);
        res.EnsureSuccessStatusCode();
        return await res.Content.ReadFromJsonAsync<TranscribeResponse>(cancellationToken: ct);
    }

    public async Task<string?> TranslateAsync(string text, string targetLanguage, CancellationToken ct = default)
    {
        var res = await _http.PostAsJsonAsync("/ai/translate",
            new { text, targetLanguage }, ct);
        res.EnsureSuccessStatusCode();
        var result = await res.Content.ReadFromJsonAsync<Dictionary<string, string>>(cancellationToken: ct);
        return result?["translatedText"];
    }
}
