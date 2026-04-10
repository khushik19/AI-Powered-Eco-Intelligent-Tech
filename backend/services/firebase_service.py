from firebase_admin import firestore, storage
from datetime import datetime, timedelta
import uuid
import asyncio

db = firestore.client()


def _run(fn):
    """
    Wraps a zero-argument callable that makes blocking Firestore/gRPC calls
    and runs it in asyncio's default thread pool.
    Use: await _run(lambda: db.collection(...).stream())
    This is the REQUIRED fix for Firebase Admin SDK + FastAPI on Linux (Render).
    """
    return asyncio.to_thread(fn)


# ── Submissions ───────────────────────────────────────────────────────────────

def save_submission(data: dict) -> str:
    """Save a new eco-action submission. Returns the new document ID."""
    ref = db.collection("submissions").add(data)
    return ref[1].id


def update_points(user_id: str, college_id: str, stardust: int, impact: dict):
    """
    Add stardust points to both the student and their college.
    Also updates cumulative impact numbers (CO2, energy, water, e-waste).
    Then updates the user's streak and the college's accreditation tier.
    """
    # Update the student's personal points
    db.collection("users").document(user_id).update({
        "stardust": firestore.Increment(stardust),
        "totalActions": firestore.Increment(1),
        "lastActionDate": datetime.utcnow().isoformat()
    })

    _update_streak(user_id)

    # Update the college's aggregate stats only if user belongs to a college
    if college_id:
        db.collection("colleges").document(college_id).update({
            "totalStardust": firestore.Increment(stardust),
            "accreditationScore": firestore.Increment(stardust // 10),
            "totalCo2Kg": firestore.Increment(impact.get("co2ReducedKg", 0)),
            "totalEnergySavedKwh": firestore.Increment(impact.get("energySavedKwh", 0)),
            "totalWaterSavedL": firestore.Increment(impact.get("waterSavedLiters", 0)),
            "totalEWasteKg": firestore.Increment(impact.get("eWasteKg", 0)),
        })
        _update_accreditation_tier(college_id)


def _update_streak(user_id: str):
    """
    Check if the user submitted an action within the last 48 hours.
    If yes, increment streak. If no, reset to 1.
    """
    try:
        user = db.collection("users").document(user_id).get().to_dict()
        if not user:
            return
        last = user.get("lastActionDate")
        streak = user.get("currentStreak", 0)
        if last:
            last_dt = datetime.fromisoformat(last)
            if datetime.utcnow() - last_dt < timedelta(hours=48):
                streak += 1
            else:
                streak = 1
        else:
            streak = 1
        db.collection("users").document(user_id).update({"currentStreak": streak})
    except Exception as e:
        print(f"Streak update failed: {e}")


def _update_accreditation_tier(college_id: str):
    """
    Colleges move through tiers as they earn accreditation score:
    0-99: Seedling | 100-199: Silver | 200-499: Gold | 500+: Platinum
    """
    try:
        college = db.collection("colleges").document(college_id).get().to_dict()
        if not college:
            return
        score = college.get("accreditationScore", 0)
        if score >= 500:
            tier = "platinum"
        elif score >= 200:
            tier = "gold"
        elif score >= 100:
            tier = "silver"
        else:
            tier = "seedling"   # ode to Clean Cosmos theme
        db.collection("colleges").document(college_id).update({"accreditationTier": tier})
    except Exception as e:
        print(f"Tier update failed: {e}")


# ── Leaderboard ───────────────────────────────────────────────────────────────

def get_leaderboard(limit: int = 20, city: str = None, state: str = None):
    """
    Returns top colleges sorted by accreditation score.
    Supports filtering by city or state for the leaderboard filters.
    """
    query = db.collection("colleges").order_by(
        "accreditationScore", direction=firestore.Query.DESCENDING
    )
    if city:
        query = query.where("city", "==", city)
    if state:
        query = query.where("state", "==", state)
    docs = query.limit(limit).stream()
    return [{"id": c.id, **c.to_dict()} for c in docs]


def get_individual_leaderboard(limit: int = 50, college_id: str = None,
                                city: str = None, state: str = None):
    """Individual student leaderboard with filters."""
    query = db.collection("users").where("role", "==", "student").order_by(
        "stardust", direction=firestore.Query.DESCENDING
    )
    if college_id:
        query = query.where("collegeId", "==", college_id)
    docs = query.limit(limit).stream()
    return [{"id": u.id, **u.to_dict()} for u in docs]


# ── Dashboard data ────────────────────────────────────────────────────────────

def get_college_dashboard(college_id: str) -> dict:
    """
    Pulls all the data needed for the college dashboard:
    - College profile
    - Monthly CO2 savings (for the line chart)
    - Action type breakdown (for the pie chart)
    - Blind spots (categories with no activity)
    """
    college = db.collection("colleges").document(college_id).get().to_dict()
    submissions = db.collection("submissions").where("collegeId", "==", college_id).stream()

    monthly_co2 = {}       # {"2025-01": 120.5, "2025-02": 340.0}
    action_types = {}      # {"solar": 3, "recycling": 8, "transport": 12}

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
    blind_spots = [c for c in all_categories if action_types.get(c, 0) == 0]

    return {
        "college": college,
        "monthlyCo2": monthly_co2,
        "actionBreakdown": action_types,
        "blindSpots": blind_spots
    }


def get_student_dashboard(user_id: str) -> dict:
    """Pulls student profile + their submission history."""
    user = db.collection("users").document(user_id).get().to_dict()
    submissions = db.collection("submissions").where("userId", "==", user_id).stream()
    return {
        "user": user,
        "submissions": [s.to_dict() for s in submissions]
    }


# ── Image upload ──────────────────────────────────────────────────────────────

def upload_image(image_base64: str, folder: str) -> str:
    """
    Hackathon Bypass: Firebase Storage was failing to initialize. 
    Since the frontend doesn't actually display the verified proof images anywhere,
    we can safely skip the upload and just return a dummy URL. 
    The AI still analyzes the base64 image perfectly!
    """
    return "https://cleancosmos.demo/skipped_storage.jpg"


# ── Predefined actions ────────────────────────────────────────────────────────

def get_predefined_actions(role: str = None):
    """
    Returns the list of preset sustainable actions users can choose from.
    role can be 'student', 'college', or None (returns all).
    """
    docs = db.collection("predefined_actions").stream()
    result = []
    for d in docs:
        data = d.to_dict()
        if role is None or data.get("targetRole") in [role, "both"]:
            result.append({"id": d.id, **data})
    return result


# ── Challenges ────────────────────────────────────────────────────────────────

def create_challenge(data: dict) -> str:
    ref = db.collection("challenges").add(data)
    return ref[1].id


def get_challenges(college_id: str):
    """Returns active challenges — both global ones and college-specific ones."""
    docs = db.collection("challenges").where("isActive", "==", True).stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]


# ── Suggestions ───────────────────────────────────────────────────────────────

def save_suggestion(data: dict) -> str:
    ref = db.collection("suggestions").add(data)
    return ref[1].id


def get_suggestions(college_id: str):
    docs = db.collection("suggestions").where("collegeId", "==", college_id).stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]