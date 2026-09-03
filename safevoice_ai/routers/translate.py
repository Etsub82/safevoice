from fastapi import APIRouter
from pydantic import BaseModel
from services.translation_service import translate_text

router = APIRouter()


class TranslateRequest(BaseModel):
    text: str
    targetLanguage: str = "en"


class TranslateResponse(BaseModel):
    translatedText: str


@router.post("/translate", response_model=TranslateResponse)
async def translate(request: TranslateRequest) -> TranslateResponse:
    result = await translate_text(request.text, request.targetLanguage)
    return TranslateResponse(translatedText=result)
