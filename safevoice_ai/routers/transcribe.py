from fastapi import APIRouter
from pydantic import BaseModel
from services.transcription_service import transcribe_audio

router = APIRouter()


class TranscribeRequest(BaseModel):
    audioUrl: str
    language: str = "en"


class TranscribeResponse(BaseModel):
    transcript: str
    success: bool


@router.post("/transcribe", response_model=TranscribeResponse)
async def transcribe(request: TranscribeRequest) -> TranscribeResponse:
    """
    Voice-to-text transcription.
    Supports: en, am, om, ti, so.
    Must complete within 60s for recordings up to 5 minutes.
    """
    return await transcribe_audio(request.audioUrl, request.language)
