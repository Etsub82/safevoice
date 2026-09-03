"""
Voice transcription service stub.
Real implementation: use Whisper or a cloud speech-to-text API.
Supports: en, am, om, ti, so (Req 15.6)
"""


async def transcribe_audio(audio_url: str, language: str) -> dict:
    # TODO: download audio from audio_url, run through Whisper model
    # Stub returns placeholder transcript
    return {
        "transcript": f"[Transcription of audio in language '{language}' — replace with real model output]",
        "success": True,
    }
