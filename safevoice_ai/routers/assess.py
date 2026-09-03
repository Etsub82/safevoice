from fastapi import APIRouter
from pydantic import BaseModel
from services.risk_service import assess_risk

router = APIRouter()


class AssessRequest(BaseModel):
    caseId: str
    reportText: str
    language: str = "en"


class AssessResponse(BaseModel):
    riskLevel: str  # "Low" | "Medium" | "High"
    potentialDuplicateCaseIds: list[str] = []


@router.post("/assess", response_model=AssessResponse)
async def assess(request: AssessRequest) -> AssessResponse:
    """
    Risk assessment + duplicate detection.
    P25: riskLevel must be exactly Low, Medium, or High.
    """
    return await assess_risk(request.caseId, request.reportText, request.language)
