from firebase_admin import firestore

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