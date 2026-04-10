"""
Submissions router — Fire-and-forget verification pattern:
1. Frontend saves doc to Firestore with status="verifying" immediately
2. Frontend POSTs to /submissions/verify (fire-and-forget, doesn't wait)
3. Backend runs AI in background, updates Firestore doc when done
4. User sees "verifying" badge → refreshes later to see "verified" + real stardust
"""

from fastapi import APIRouter, BackgroundTasks
from pydantic import BaseModel
from services.ai_service import classify_with_openrouter
import asyncio
import os

router = APIRouter()


class VerifyRequest(BaseModel):
    submissionId: str          # Firestore doc ID to update
    userId: str
    collegeId: str = ""
    imageBase64: str
    description: str


async def _run_verification(submission_id: str, user_id: str, college_id: str,
                             image_base64: str, description: str):
    """
    Background task — runs after endpoint has already returned 202.
    1. AI classifies image
    2. Updates submission doc: status=verified, real stardust, CO2, etc.
    3. Increments user stardust in Firestore
    """
    print(f"[BG] Starting verification for submission {submission_id}")
    try:
        # Step 1: AI classification (uses OpenRouter — pure HTTP, no Firebase)
        result = await asyncio.to_thread(
            classify_with_openrouter, image_base64, description
        )
        print(f"[BG] AI result for {submission_id}: {result.get('actionType')} / {result.get('stardustAwarded')} stardust")

        # Step 2: Update Firestore doc via Firebase Admin SDK
        try:
            from firebase_admin import firestore as fs
            db = fs.client()

            update_data = {
                "status":          "verified",
                "verified":        result.get("isLegitimate", True),
                "actionType":      result.get("actionType", "other"),
                "stardustAwarded": result.get("stardustAwarded", 25),
                "co2ReducedKg":    result.get("co2ReducedKg", 0),
                "energySavedKwh":  result.get("energySavedKwh", 0),
                "waterSavedLiters": result.get("waterSavedLiters", 0),
                "eWasteKg":        result.get("eWasteKg", 0),
                "estimatedCostSavingRupees": result.get("estimatedCostSavingRupees", 0),
                "impactSummary":   result.get("impactSummary", ""),
                "realWorldEquivalent": result.get("realWorldEquivalent", ""),
                "aiClassified":    True,
                "verifiedAt":      fs.SERVER_TIMESTAMP,
            }

            await asyncio.to_thread(
                lambda: db.collection("submissions").document(submission_id).update(update_data)
            )
            print(f"[BG] Updated submission {submission_id} → verified")

        except Exception as fe:
            print(f"[BG] Firestore update failed for {submission_id}: {fe}")
            # Even if Firestore fails, try to update stardust
            return

        # Step 3: Increment user stardust in Firestore
        try:
            stardust = result.get("stardustAwarded", 25)
            await asyncio.to_thread(
                lambda: db.collection("users").document(user_id).update({
                    "stardust":       fs.Increment(stardust),
                    "totalActions":   fs.Increment(1),
                })
            )
            print(f"[BG] Awarded {stardust} stardust to user {user_id}")
        except Exception as ue:
            print(f"[BG] Stardust update failed for user {user_id}: {ue}")

    except Exception as e:
        # Mark submission as failed so UI can show error state
        print(f"[BG] Verification failed entirely for {submission_id}: {e}")
        try:
            from firebase_admin import firestore as fs
            db = fs.client()
            await asyncio.to_thread(
                lambda: db.collection("submissions").document(submission_id).update({
                    "status": "verified",      # still approved — AI just couldn't run
                    "verified": True,
                    "stardustAwarded": 25,     # default stardust
                    "aiClassified": False,
                })
            )
            # Give default stardust even when AI fails
            await asyncio.to_thread(
                lambda: db.collection("users").document(user_id).update({
                    "stardust":     fs.Increment(25),
                    "totalActions": fs.Increment(1),
                })
            )
        except Exception:
            pass


@router.post("/verify", status_code=202)
async def verify_submission(req: VerifyRequest, background_tasks: BackgroundTasks):
    """
    Fire and forget — returns 202 immediately.
    AI classification + Firestore update happen in the background.
    """
    background_tasks.add_task(
        _run_verification,
        req.submissionId,
        req.userId,
        req.collegeId,
        req.imageBase64,
        req.description,
    )
    return {"queued": True, "submissionId": req.submissionId, "message": "Verification started"}


@router.post("/classify")
async def classify_action(req: VerifyRequest):
    """Synchronous classify — for testing only."""
    result = await asyncio.to_thread(
        classify_with_openrouter, req.imageBase64, req.description
    )
    return {"success": True, **result}


# Predefined actions (hardcoded — no Firebase needed)
PREDEFINED_ACTIONS = {
    "student": [
        "Used public transport instead of private vehicle",
        "Recycled plastic/paper/glass waste",
        "Composted food waste",
        "Reduced single-use plastic usage",
        "Saved electricity (turned off unused lights/devices)",
        "Collected and disposed e-waste properly",
        "Saved water (shorter shower, fixed leaks)",
        "Planted a tree or participated in plantation drive",
        "Participated in campus cleanliness drive",
        "Used reusable bag/bottle instead of disposable",
    ],
    "college": [
        "Installed solar panels or renewable energy system",
        "Launched campus recycling program",
        "Organized e-waste collection drive",
        "Implemented rainwater harvesting",
        "Switched to LED lighting across campus",
        "Created campus garden/composting facility",
        "Introduced EV charging station",
        "Reduced paper usage via digitalization",
        "Organized sustainability awareness workshop",
        "Achieved green building certification",
    ],
}


@router.get("/predefined/{role}")
async def get_predefined(role: str):
    """Hardcoded predefined actions — no Firebase needed."""
    actions = PREDEFINED_ACTIONS.get(role, PREDEFINED_ACTIONS["student"])
    return [{"id": str(i), "title": a, "category": "general"} for i, a in enumerate(actions)]