from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from firebase_admin import firestore
from datetime import datetime
import asyncio

router = APIRouter()
db = firestore.client()


class RegisterRequest(BaseModel):
    uid: str                    # Firebase UID (from Flutter after Firebase auth)
    name: str
    email: str = ""
    phone: str = ""
    city: str = ""
    state: str = ""
    country: str = ""
    role: str                   # "individual" | "student" | "college"
    institutionName: str = ""
    profilePhotoUrl: str = ""


def _do_register(req: RegisterRequest):
    """Blocking Firestore writes — runs in thread pool."""
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
        "createdAt": datetime.utcnow().isoformat(),
    }
    user_ref = db.collection("users").document(req.uid)
    # merge=True: won't overwrite stardust/streak for returning users
    user_ref.set(user_data, merge=True)

    # Only initialize counters if the doc is brand new
    snap = user_ref.get().to_dict() or {}
    if "stardust" not in snap:
        user_ref.update({"stardust": 0, "totalActions": 0, "currentStreak": 0, "lastActionDate": None})

    # If college/org, also create the colleges doc
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
            "createdAt": datetime.utcnow().isoformat(),
        }, merge=True)

    return {"success": True, "uid": req.uid}


def _do_get_user(uid: str):
    """Blocking Firestore read — runs in thread pool."""
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        return None
    return {"uid": uid, **doc.to_dict()}


@router.post("/register")
async def register_user(req: RegisterRequest):
    """
    Called after Firebase Auth creates the user.
    Creates (or updates) the Firestore profile. Safe to call on every login.
    """
    try:
        return await asyncio.to_thread(_do_register, req)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{uid}")
async def get_user(uid: str):
    """Fetch a user profile by Firebase UID."""
    result = await asyncio.to_thread(_do_get_user, uid)
    if result is None:
        raise HTTPException(status_code=404, detail="User not found")
    return result