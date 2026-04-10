from fastapi import APIRouter
from pydantic import BaseModel
from services.firebase_service import create_challenge, get_challenges
from datetime import datetime
import asyncio

router = APIRouter()

class ChallengeCreate(BaseModel):
    collegeId: str
    title: str
    description: str
    pointReward: int
    deadline: str

@router.post("/create")
async def create(req: ChallengeCreate):
    challenge = req.dict()
    challenge["isActive"] = True
    challenge["createdAt"] = datetime.utcnow().isoformat()
    cid = await asyncio.to_thread(create_challenge, challenge)
    return {"id": cid}

@router.get("/{collegeId}")
async def list_challenges(collegeId: str):
    return await asyncio.to_thread(get_challenges, collegeId)