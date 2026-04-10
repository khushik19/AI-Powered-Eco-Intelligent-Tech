from fastapi import APIRouter
from pydantic import BaseModel
from services.firebase_service import create_challenge, get_challenges
from datetime import datetime

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
    id = create_challenge(challenge)
    return {"id": id}

@router.get("/{collegeId}")
async def list_challenges(collegeId: str):
    return get_challenges(collegeId)