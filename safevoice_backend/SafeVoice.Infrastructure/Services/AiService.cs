using System.Net.Http.Json;
using SafeVoice.Core.Interfaces;

namespace SafeVoice.Infrastructure.Services;

public class AiService : IAiService
{
    private readonly HttpClient _http;

    public AiService(HttpClient http) => _http = http;

    public async Task<AiAssessResponse?> AssessRiskAsync(AiAssessRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _http.PostAsJsonAsync("/ai/assess", request, ct);
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<AiAssessResponse>(cancellationToken: ct);
        }
        catch { return null; }
    }

    public async Task<TranscribeResponse?> TranscribeAudioAsync(TranscribeRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _http.PostAsJsonAsync("/ai/transcribe", request, ct);
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadFromJsonAsync<TranscribeResponse>(cancellationToken: ct);
        }
        catch { return null; }
    }

    public async Task<string?> TranslateAsync(string text, string targetLanguage, CancellationToken ct = default)
    {
        try
        {
            var response = await _http.PostAsJsonAsync("/ai/translate",
                new { text, targetLanguage }, ct);
            response.EnsureSuccessStatusCode();
            var result = await response.Content.ReadFromJsonAsync<Dictionary<string, string>>(cancellationToken: ct);
            return result?["translatedText"];
        }
        catch { return null; }
    }
}
