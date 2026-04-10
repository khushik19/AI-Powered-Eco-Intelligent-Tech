from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_admin import firestore, auth
from datetime import datetime

router = APIRouter()
db = firestore.client()


class RegisterRequest(BaseModel):
    uid: str                    # Firebase UID (from Flutter after Firebase auth)
    name: str
    email: str = ""
    phone: str = ""
    city: str
    state: str
    country: str
    role: str                   # "individual" | "student" | "college"
    institutionName: str = ""   # for student/employee
    profilePhotoUrl: str = ""


@router.post("/register")
async def register_user(req: RegisterRequest):
    """
    Called after Firebase Auth creates the user.
    Creates (or updates) the Firestore profile document.
    Uses merge=True so calling this for returning users is safe.
    """
    try:
        user_data = {
            "name": req.name,
            "email": req.email,
            "phone": req.phone,
            "city": req.city,
            "state": req.state,
            "country": req.country,
            "role": req.role,
            "institutionName": req.institutionName,
            "profilePhotoUrl": req.profilePhotoUrl,
            "createdAt": datetime.utcnow().isoformat()
        }
        # merge=True: won't overwrite stardust/streak if user already exists
        db.collection("users").document(req.uid).set(user_data, merge=True)
        # Ensure these fields exist for new users (not overwritten on re-login)
        db.collection("users").document(req.uid).update({
            k: firestore.SERVER_TIMESTAMP if k == 'lastActionDate' else v
            for k, v in {
                "stardust": 0, "totalActions": 0,
                "currentStreak": 0, "lastActionDate": None
            }.items()
        })

        # If it's a college/org, also create a colleges document
        if req.role == "college":
            db.collection("colleges").document(req.uid).set({
                "name": req.name,
                "email": req.email,
                "phone": req.phone,
                "city": req.city,
                "state": req.state,
                "country": req.country,
                "totalStardust": 0,
                "accreditationScore": 0,
                "accreditationTier": "seedling",
                "totalCo2Kg": 0,
                "totalEnergySavedKwh": 0,
                "totalWaterSavedL": 0,
                "totalEWasteKg": 0,
                "studentCount": 0,
                "createdAt": datetime.utcnow().isoformat()
            })

        return {"success": True, "uid": req.uid}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{uid}")
async def get_user(uid: str):
    """Fetch a user's profile by their Firebase UID."""
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    return {"uid": uid, **doc.to_dict()}