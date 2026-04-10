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


def _fetch_individuals(limit, college_id, city, state):
    """
    Blocking Firestore read — runs in thread pool.
    Fetches all users sorted by stardust, excluding college_org.
    Note: We cannot filter by city/state AND order by stardust without a composite
    index, so we filter in Python instead.
    """
    query = db.collection("users").order_by(
        "stardust", direction=firestore.Query.DESCENDING
    )
    if college_id:
        query = query.where("collegeId", "==", college_id)

    results = []
    for u in query.limit(limit * 3).stream():  # fetch extra to account for filtered-out orgs
        d = u.to_dict()
        role = d.get("role", "")
        if role in ("college_org", "college"):
            continue
        if city and d.get("city", "").lower() != city.lower():
            continue
        if state and d.get("state", "").lower() != state.lower():
            continue
        results.append({"id": u.id, **d})
        if len(results) >= limit:
            break
    return results


@router.get("/colleges")
async def college_leaderboard(city: str = None, state: str = None, limit: int = 20):
    """Top colleges by accreditation score."""
    return await asyncio.to_thread(_fetch_colleges, limit, city, state)


@router.get("/individuals")
async def individual_leaderboard(
    college_id: str = None, city: str = None,
    state: str = None, limit: int = 50
):
    """Top individual users by stardust points (excludes college orgs)."""
    return await asyncio.to_thread(_fetch_individuals, limit, college_id, city, state)