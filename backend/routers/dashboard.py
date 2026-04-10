from fastapi import APIRouter
from services.firebase_service import get_college_dashboard, get_student_dashboard
from services.ai_service import get_recommendations
import asyncio

router = APIRouter()

@router.get("/college/{college_id}")
async def college_dash(college_id: str):
    """College dashboard: profile, CO2 chart data, action breakdown, AI recommendations."""
    # Use the shared logic from firebase_service.py
    data = await asyncio.to_thread(get_college_dashboard, college_id)
    
    # Add AI recommendations
    try:
        data["recommendations"] = await asyncio.to_thread(get_recommendations, data)
    except Exception as e:
        print(f"Recommendations failed: {e}")
        data["recommendations"] = []
        
    return data

@router.get("/student/{user_id}")
async def student_dash(user_id: str):
    """Student profile + submission history."""
    return await asyncio.to_thread(get_student_dashboard, user_id)