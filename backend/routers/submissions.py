from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.ai_service import classify_with_openrouter
from services.firebase_service import (
    save_submission, update_points, upload_image, get_predefined_actions
)
from datetime import datetime

router = APIRouter()


class SubmissionRequest(BaseModel):
    userId: str
    collegeId: str
    role: str           
    imageBase64: str
    description: str
    isPredefined: bool = False
    predefinedActionId: str = None


@router.post("/submit")
async def submit_action(req: SubmissionRequest):
    try:
        result = classify_with_openrouter(req.imageBase64, req.description)

        image_url = upload_image(req.imageBase64, f"submissions/{req.collegeId}")

        submission = {
            "userId": req.userId,
            "collegeId": req.collegeId,
            "role": req.role,
            "description": req.description,
            "imageUrl": image_url,
            "isPredefined": req.isPredefined,
            "actionType": result["actionType"],
            "stardustAwarded": result["stardustAwarded"],
            "co2ReducedKg": result.get("co2ReducedKg", 0),
            "energySavedKwh": result.get("energySavedKwh", 0),
            "waterSavedLiters": result.get("waterSavedLiters", 0),
            "eWasteKg": result.get("eWasteKg", 0),
            "estimatedCostSavingRupees": result.get("estimatedCostSavingRupees", 0),
            "impactSummary": result["impactSummary"],
            "realWorldEquivalent": result["realWorldEquivalent"],
            "status": "approved",
            "createdAt": datetime.utcnow().isoformat()
        }

        submission_id = save_submission(submission)
        update_points(req.userId, req.collegeId, result["stardustAwarded"], result)

        return {"success": True, "submissionId": submission_id, **result}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/predefined/{role}")
def get_predefined(role: str):
    """Returns the list of preset eco-actions for the given role."""
    return get_predefined_actions(role)