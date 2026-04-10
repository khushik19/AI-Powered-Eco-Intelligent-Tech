from fastapi import APIRouter
from firebase_admin import firestore
from services.ai_service import get_recommendations
import asyncio

router = APIRouter()
db = firestore.client()


def _fetch_college_dashboard(college_id: str) -> dict:
    """Blocking — runs in thread pool."""
    college = db.collection("colleges").document(college_id).get().to_dict() or {}
    submissions = db.collection("submissions").where("collegeId", "==", college_id).stream()

    monthly_co2 = {}
    action_types = {}
    for s in submissions:
        d = s.to_dict()
        month = d.get("createdAt", "")[:7]
        monthly_co2[month] = monthly_co2.get(month, 0) + d.get("co2ReducedKg", 0)
        at = d.get("actionType", "other")
        action_types[at] = action_types.get(at, 0) + 1

    all_categories = [
        "solar", "composting", "recycling", "eWaste",
        "water", "energy", "transport", "cutsWaste",
        "optimizesResources", "lowersEmissions"
    ]
    return {
        "college": college,
        "monthlyCo2": monthly_co2,
        "actionBreakdown": action_types,
        "blindSpots": [c for c in all_categories if action_types.get(c, 0) == 0],
    }


def _fetch_student_dashboard(user_id: str) -> dict:
    """Blocking — runs in thread pool."""
    user = db.collection("users").document(user_id).get().to_dict() or {}
    submissions = [
        s.to_dict()
        for s in db.collection("submissions").where("userId", "==", user_id).stream()
    ]
    return {"user": user, "submissions": submissions}


@router.get("/college/{college_id}")
async def college_dash(college_id: str):
    """College dashboard: profile, CO2 chart data, action breakdown, AI recommendations."""
    data = await asyncio.to_thread(_fetch_college_dashboard, college_id)
    try:
        data["recommendations"] = get_recommendations(data)
    except Exception as e:
        print(f"Recommendations failed: {e}")
        data["recommendations"] = []
    return data


@router.get("/student/{user_id}")
async def student_dash(user_id: str):
    """Student profile + submission history."""
    return await asyncio.to_thread(_fetch_student_dashboard, user_id)