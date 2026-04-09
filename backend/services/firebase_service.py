from firebase_admin import firestore
from datetime import datetime, date, timezone

db = firestore.client()

def save_submission(data: dict) -> str:
    ref = db.collection("submissions").add(data)
    return ref[1].id

def update_points(user_id: str, college_id: str, points: int):
    db.collection("users").document(user_id).update({
        "points": firestore.Increment(points),
        "totalActions": firestore.Increment(1)
    })
    db.collection("colleges").document(college_id).update({
        "totalPoints": firestore.Increment(points),
        "accreditationScore": firestore.Increment(points // 10)
    })

def get_leaderboard():
    colleges = db.collection("colleges").order_by(
        "accreditationScore", direction=firestore.Query.DESCENDING
    ).limit(20).stream()
    return [{"id": c.id, **c.to_dict()} for c in colleges]

def create_challenge(data: dict) -> str:
    ref = db.collection("challenges").add(data)
    return ref[1].id

def get_challenges(college_id: str):
    docs = db.collection("challenges")\
        .where("collegeId", "==", college_id)\
        .where("isActive", "==", True).stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]


# ---------------------------------------------------------------------------
# Step 3: Aggregator Logic
# Sums all co2ReducedKg from submissions for a given college and writes
# the total back to the colleges document.
# ---------------------------------------------------------------------------
def aggregate_college_totals(college_id: str) -> dict:
    """
    Recalculates totalCo2Kg for a college by summing co2ReducedKg
    across all approved submissions for that college.
    Call this after every new submission is approved.
    """
    submissions = (
        db.collection("submissions")
        .where("collegeId", "==", college_id)
        .stream()
    )

    total_co2 = sum(
        doc.to_dict().get("co2ReducedKg", 0.0) for doc in submissions
    )

    db.collection("colleges").document(college_id).update({
        "totalCo2Kg": total_co2
    })

    return {"collegeId": college_id, "totalCo2Kg": total_co2}


# ---------------------------------------------------------------------------
# Step 3: Streak Logic
# Checks lastActionDate for a user. If their last action was exactly
# yesterday, increments the streak. Otherwise resets it to 1.
# ---------------------------------------------------------------------------
def update_user_streak(user_id: str) -> dict:
    """
    Call this every time a user completes an eco-action.
    - Consecutive day  -> streak += 1
    - Same day (double action) -> streak unchanged
    - Gap of >1 day    -> streak resets to 1
    Updates lastActionDate to today.
    """
    today = date.today()
    user_ref = db.collection("users").document(user_id)
    user_data = user_ref.get().to_dict() or {}

    last_action = user_data.get("lastActionDate")
    current_streak = user_data.get("streak", 0)

    # Normalize lastActionDate to a date object
    if isinstance(last_action, datetime):
        last_date = last_action.date()
    elif isinstance(last_action, date):
        last_date = last_action
    else:
        last_date = None

    delta = (today - last_date).days if last_date else None

    if delta is None or delta > 1:
        new_streak = 1          # First action ever, or streak broken
    elif delta == 1:
        new_streak = current_streak + 1   # Consecutive day
    else:
        new_streak = current_streak       # Same day, no change

    user_ref.update({
        "streak": new_streak,
        "lastActionDate": datetime.combine(today, datetime.min.time(), timezone.utc)
    })

    return {"userId": user_id, "streak": new_streak}