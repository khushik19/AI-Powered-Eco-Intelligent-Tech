from fastapi import APIRouter
from services.firebase_service import get_leaderboard, get_individual_leaderboard

router = APIRouter()


@router.get("/colleges")
def college_leaderboard(city: str = None, state: str = None, limit: int = 20):
    """
    Top colleges by accreditation score.
    Optional filters: ?city=Chennai&state=TamilNadu
    """
    return get_leaderboard(limit=limit, city=city, state=state)


@router.get("/individuals")
def individual_leaderboard(
    college_id: str = None, city: str = None,
    state: str = None, limit: int = 50
):
    """
    Top individual students by stardust points.
    Optional filters: ?college_id=xyz
    """
    return get_individual_leaderboard(
        limit=limit, college_id=college_id, city=city, state=state
    )