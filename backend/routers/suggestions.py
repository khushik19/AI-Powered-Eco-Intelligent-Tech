from fastapi import APIRouter
from pydantic import BaseModel
from services.firebase_service import save_suggestion, get_suggestions
from datetime import datetime
import asyncio

router = APIRouter()


class SuggestionRequest(BaseModel):
    userId: str
    collegeId: str
    title: str
    description: str


@router.post("/")
async def suggest(req: SuggestionRequest):
    """Student submits a suggestion for a new sustainable practice."""
    doc = {
        **req.dict(),
        "status": "pending",
        "upvotes": 0,
        "createdAt": datetime.utcnow().isoformat()
    }
    return {"id": await asyncio.to_thread(save_suggestion, doc)}


@router.get("/{college_id}")
async def list_suggestions(college_id: str):
    """College admin views all suggestions from their students."""
    return await asyncio.to_thread(get_suggestions, college_id)