from firebase_admin import firestore


def get_db():
    """Lazy getter — only called after Firebase is initialized in main.py."""
    return firestore.client()


def save_submission(data: dict) -> str:
    db = get_db()
    ref = db.collection("submissions").add(data)
    return ref[1].id


def update_points(user_id: str, college_id: str, points: int):
    db = get_db()
    db.collection("users").document(user_id).set({
        "points": firestore.Increment(points),
        "totalActions": firestore.Increment(1)
    }, merge=True)
    db.collection("colleges").document(college_id).set({
        "totalPoints": firestore.Increment(points),
        "accreditationScore": firestore.Increment(points // 10)
    }, merge=True)


def get_leaderboard():
    db = get_db()
    colleges = db.collection("colleges").order_by(
        "accreditationScore", direction=firestore.Query.DESCENDING
    ).limit(20).stream()
    return [{"id": c.id, **c.to_dict()} for c in colleges]


def create_challenge(data: dict) -> str:
    db = get_db()
    ref = db.collection("challenges").add(data)
    return ref[1].id


def get_challenges(college_id: str):
    db = get_db()
    docs = db.collection("challenges")\
        .where("collegeId", "==", college_id)\
        .where("isActive", "==", True).stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]