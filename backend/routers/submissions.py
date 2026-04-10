from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.ai_service import classify_with_openrouter
from services.firebase_service import save_submission, update_points, get_predefined_actions
from datetime import datetime
import asyncio

router = APIRouter()


class SubmissionRequest(BaseModel):
    userId: str
    collegeId: str = ""
    role: str = "student"
    imageBase64: str
    description: str
    isPredefined: bool = False
    predefinedActionId: str = None
    imageUrl: str = ""   # Frontend can upload to Firebase Storage and pass URL here


@router.post("/submit")
async def submit_action(req: SubmissionRequest):
    try:
        # Step 1: AI classifies the image + description (OpenRouter)
        result = await asyncio.to_thread(
            classify_with_openrouter, req.imageBase64, req.description
        )

        # Step 2: Build Firestore document
        # Image URL comes from frontend (it uploads directly to Firebase Storage)
        # Backend never touches Firebase Storage — avoids JWT/timeout issues
        submission = {
            "userId": req.userId,
            "collegeId": req.collegeId,
            "role": req.role,
            "description": req.description,
            "imageUrl": req.imageUrl,   # passed from frontend or empty string
            "isPredefined": req.isPredefined,
            "actionType": result.get("actionType", "other"),
            "stardustAwarded": result.get("stardustAwarded", 10),
            "co2ReducedKg": result.get("co2ReducedKg", 0),
            "energySavedKwh": result.get("energySavedKwh", 0),
            "waterSavedLiters": result.get("waterSavedLiters", 0),
            "eWasteKg": result.get("eWasteKg", 0),
            "estimatedCostSavingRupees": result.get("estimatedCostSavingRupees", 0),
            "impactSummary": result.get("impactSummary", ""),
            "realWorldEquivalent": result.get("realWorldEquivalent", ""),
            "status": "approved",
            "createdAt": datetime.utcnow().isoformat()
        }

        # Step 3: Save to Firestore + update points (both in thread pool)
        submission_id = await asyncio.to_thread(save_submission, submission)
        await asyncio.to_thread(
            update_points,
            req.userId,
            req.collegeId,
            result.get("stardustAwarded", 10),
            result
        )

        return {"success": True, "submissionId": submission_id, **result}

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/predefined/{role}")
async def get_predefined(role: str):
    """Returns the list of preset eco-actions for the given role."""
    return await asyncio.to_thread(get_predefined_actions, role)