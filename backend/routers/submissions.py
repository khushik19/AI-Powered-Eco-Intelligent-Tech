from fastapi import APIRouter
from pydantic import BaseModel
from services.ai_service import classify_with_openrouter
import asyncio

router = APIRouter()


class ClassifyRequest(BaseModel):
    imageBase64: str
    description: str


class SubmissionRequest(BaseModel):
    imageBase64: str
    description: str
    userId: str = ""
    collegeId: str = ""
    role: str = "student"
    isPredefined: bool = False


@router.post("/classify")
async def classify_action(req: ClassifyRequest):
    """
    Pure AI classification — NO Firebase.
    Returns AI analysis result (stardust, CO2, actionType, etc.).
    The Flutter frontend saves to Firestore directly.
    """
    result = await asyncio.to_thread(
        classify_with_openrouter, req.imageBase64, req.description
    )
    return {"success": True, **result}


@router.post("/submit")
async def submit_action(req: SubmissionRequest):
    """
    Same as /classify but accepts full submission fields.
    Firestore writes are handled by the Flutter frontend.
    """
    result = await asyncio.to_thread(
        classify_with_openrouter, req.imageBase64, req.description
    )
    return {"success": True, **result}


# Predefined actions list (no Firebase needed - hardcoded fallback)
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