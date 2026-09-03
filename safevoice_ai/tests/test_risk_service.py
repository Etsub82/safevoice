"""
Property-based tests for the AI risk service.
P25: riskLevel must always be exactly Low, Medium, or High.
"""
import pytest
from hypothesis import given, settings
from hypothesis import strategies as st
from services.risk_service import assess_risk, VALID_RISK_LEVELS


@given(
    case_id=st.uuids().map(str),
    report_text=st.text(min_size=0, max_size=2000),
    language=st.sampled_from(["en", "am", "om", "ti", "so"]),
)
@settings(max_examples=100)
def test_risk_level_always_valid(case_id, report_text, language):
    """P25: risk level must be Low, Medium, or High for any input."""
    import asyncio
    result = asyncio.get_event_loop().run_until_complete(
        assess_risk(case_id, report_text, language)
    )
    assert result["riskLevel"] in VALID_RISK_LEVELS


@given(report_text=st.just("kill weapon rape threat knife"))
def test_high_risk_keywords_produce_high(report_text):
    import asyncio
    result = asyncio.get_event_loop().run_until_complete(
        assess_risk("test-id", report_text, "en")
    )
    assert result["riskLevel"] == "High"
