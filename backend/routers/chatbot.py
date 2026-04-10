from fastapi import APIRouter
from pydantic import BaseModel
from services.ai_service import chat_with_openrouter
import asyncio

router = APIRouter()


class ChatRequest(BaseModel):
    query: str
    history: list = []


@router.post("/message")
async def chat(req: ChatRequest):
    """
    Eco-chatbot endpoint. Runs the synchronous OpenRouter call
    in a thread pool to avoid blocking the async event loop.
    """
    response = await asyncio.to_thread(chat_with_openrouter, req.query, req.history)
    return {"response": response}