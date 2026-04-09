from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from services.ai_service import classify_with_gemini
from services.firebase_service import save_submission, update_points
from datetime import datetime

router = APIRouter()

class SubmissionRequest(BaseModel):
    userId: str
    collegeId: str
    role: str          # "student" or "college"
    imageBase64: str
    description: str

@router.post("/submit")
async def submit_action(req: SubmissionRequest):
    try:
        result = classify_with_gemini(req.imageBase64, req.description)

        submission = {
            "userId": req.userId,
            "collegeId": req.collegeId,
            "role": req.role,
            "description": req.description,
            "actionType": result["actionType"],
            "pointsAwarded": result["pointsAwarded"],
            "impactSummary": result["impactSummary"],
            "realWorldEquivalent": result["realWorldEquivalent"],
            "status": "approved",
            "createdAt": datetime.utcnow().isoformat()
        }

        submission_id = save_submission(submission)
        update_points(req.userId, req.collegeId, result["pointsAwarded"])

        return {"success": True, "submissionId": submission_id, **result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))