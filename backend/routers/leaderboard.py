from fastapi import APIRouter
from services.firebase_service import get_leaderboard

router = APIRouter()

@router.get("/colleges")
def college_leaderboard():
    return get_leaderboard()