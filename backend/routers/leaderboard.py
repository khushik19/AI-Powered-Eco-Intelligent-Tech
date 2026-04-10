from fastapi import APIRouter
from firebase_admin import firestore
import asyncio

router = APIRouter()

db = firestore.client()


def _fetch_colleges(limit, city, state):
    """Blocking Firestore read — runs in thread pool."""
    query = db.collection("colleges").order_by(
        "accreditationScore", direction=firestore.Query.DESCENDING
    )
    if city:
        query = query.where("city", "==", city)
    if state:
        query = query.where("state", "==", state)
    return [{"id": c.id, **c.to_dict()} for c in query.limit(limit).stream()]


def _fetch_individuals(limit, college_id):
    """Blocking Firestore read — runs in thread pool."""
    query = db.collection("users").where("role", "==", "student").order_by(
        "stardust", direction=firestore.Query.DESCENDING
    )
    if college_id:
        query = query.where("collegeId", "==", college_id)
    return [{"id": u.id, **u.to_dict()} for u in query.limit(limit).stream()]


@router.get("/colleges")
async def college_leaderboard(city: str = None, state: str = None, limit: int = 20):
    """Top colleges by accreditation score."""
    return await asyncio.to_thread(_fetch_colleges, limit, city, state)


@router.get("/individuals")
async def individual_leaderboard(
    college_id: str = None, city: str = None,
    state: str = None, limit: int = 50
):
    """Top individual students by stardust points."""
    return await asyncio.to_thread(_fetch_individuals, limit, college_id)