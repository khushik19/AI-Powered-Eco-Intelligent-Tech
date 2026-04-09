from fastapi import APIRouter
from services.firebase_service import get_college_dashboard, get_student_dashboard
from services.ai_service import get_recommendations

router = APIRouter()


@router.get("/college/{college_id}")
def college_dash(college_id: str):
    """
    Returns everything the college dashboard needs:
    profile data, monthly CO2 chart data, action breakdown, blind spots,
    and AI-generated recommendations.
    """
    data = get_college_dashboard(college_id)
    try:
        data["recommendations"] = get_recommendations(data)
    except Exception as e:
        print(f"Recommendations failed: {e}")
        data["recommendations"] = []
    return data


@router.get("/student/{user_id}")
def student_dash(user_id: str):
    """Returns student profile and their submission history."""
    return get_student_dashboard(user_id)