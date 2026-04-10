from fastapi import APIRouter
from pydantic import BaseModel
from services.ai_service import chat_with_openrouter

router = APIRouter()

class ChatRequest(BaseModel):
    query: str
    history: list = []   

@router.post("/message")
async def chat(req: ChatRequest):
    response = chat_with_openrouter(req.query, req.history)
    return {"response": response}