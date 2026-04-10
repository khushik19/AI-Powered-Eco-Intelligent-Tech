from fastapi import APIRouter
from pydantic import BaseModel
from services.ai_service import classify_with_openrouter
import asyncio

router = APIRouter()


class ClassifyRequest(BaseModel):
    imageBase64: str = ""
    description: str


class SubmissionRequest(BaseModel):
    imageBase64: str = ""
    description: str
    userId: str = ""
    collegeId: str = ""
    role: str = "student"
    isPredefined: bool = False


@router.post("/classify")
async def classify_action(req: ClassifyRequest):
    """
    AI validation + classification endpoint.

    Returns:
      - success=True  + all impact fields  → save the submission in Flutter
      - success=False + rejectionReason    → show rejection message to user, do NOT save
    """
    result = await asyncio.to_thread(
        classify_with_openrouter, req.imageBase64, req.description
    )

    is_legitimate = result.get("isLegitimate", True)

    if not is_legitimate:
        reason = result.get("rejectionReason") or "This doesn't appear to be a valid eco-action."
        print(f"[Submission] REJECTED: {reason}")
        return {
            "success": False,
            "rejected": True,
            "rejectionReason": reason,
            "impactSummary": result.get("impactSummary", reason),
        }

    # Legitimate — return full result for Flutter to save to Firestore
    print(
        f"[Submission] APPROVED: actionType={result.get('actionType')} "
        f"stardust={result.get('stardustAwarded')}"
    )
    return {"success": True, "rejected": False, **result}


@router.post("/submit")
async def submit_action(req: SubmissionRequest):
    """
    Same as /classify but accepts full submission metadata.
    Firestore writes are still done by the Flutter frontend after approval.
    """
    result = await asyncio.to_thread(
        classify_with_openrouter, req.imageBase64, req.description
    )

    is_legitimate = result.get("isLegitimate", True)

    if not is_legitimate:
        reason = result.get("rejectionReason") or "This doesn't appear to be a valid eco-action."
        print(f"[Submission] REJECTED (userId={req.userId}): {reason}")
        return {
            "success": False,
            "rejected": True,
            "rejectionReason": reason,
            "impactSummary": result.get("impactSummary", reason),
        }

    print(
        f"[Submission] APPROVED (userId={req.userId}): "
        f"actionType={result.get('actionType')} stardust={result.get('stardustAwarded')}"
    )
    return {"success": True, "rejected": False, **result}


# ── Predefined actions ────────────────────────────────────────────────────────

PREDEFINED_ACTIONS = {
    "student": [
        "Used public transport instead of private vehicle",
        "Recycled plastic/paper/glass waste",
        "Composted food waste",
        "Reduced single-use plastic usage",
        "Saved electricity (turned off unused lights/devices)",
        "Collected and disposed e-waste properly",
        "Saved water (shorter shower, fixed leaks)",
        "Planted a tree or participated in plantation drive",
        "Participated in campus cleanliness drive",
        "Used reusable bag/bottle instead of disposable",
    ],
    "college": [
        "Installed solar panels or renewable energy system",
        "Launched campus recycling program",
        "Organized e-waste collection drive",
        "Implemented rainwater harvesting",
        "Switched to LED lighting across campus",
        "Created campus garden/composting facility",
        "Introduced EV charging station",
        "Reduced paper usage via digitalization",
        "Organized sustainability awareness workshop",
        "Achieved green building certification",
    ],
}


@router.get("/predefined/{role}")
async def get_predefined(role: str):
    """Returns preset eco-actions. Hardcoded — no Firebase needed."""
    actions = PREDEFINED_ACTIONS.get(role, PREDEFINED_ACTIONS["student"])
    return [{"id": str(i), "title": a, "category": "general"} for i, a in enumerate(actions)]