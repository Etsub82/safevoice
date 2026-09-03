"""
Risk assessment service.
P25: returned riskLevel must be exactly one of: Low, Medium, High.
Real implementation would use a trained NLP model.
This stub uses keyword heuristics as a placeholder.
"""

VALID_RISK_LEVELS = {"Low", "Medium", "High"}

HIGH_RISK_KEYWORDS = [
    "kill", "murder", "dead", "rape", "kidnap", "weapon", "knife", "gun",
    "threat", "bleeding", "hospital", "unconscious", "child abuse",
]
LOW_RISK_KEYWORDS = ["verbal", "argument", "shouting", "insult"]


async def assess_risk(case_id: str, report_text: str, language: str) -> dict:
    text_lower = report_text.lower()

    if any(kw in text_lower for kw in HIGH_RISK_KEYWORDS):
        risk_level = "High"
    elif any(kw in text_lower for kw in LOW_RISK_KEYWORDS):
        risk_level = "Low"
    else:
        risk_level = "Medium"

    # P25 invariant: always return a valid enum value
    assert risk_level in VALID_RISK_LEVELS, f"Invalid risk level: {risk_level}"

    return {
        "riskLevel": risk_level,
        "potentialDuplicateCaseIds": [],  # TODO: similarity search against open cases
    }
