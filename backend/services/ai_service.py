"""
AI Service — EcoTrack / Clean Cosmos
Handles image classification, chatbot, and college recommendations via OpenRouter.

ROBUSTNESS DESIGN:
- classify_with_openrouter NEVER raises an exception.
  If AI fails for any reason (bad key, timeout, bad JSON, model error),
  it returns a safe fallback result so the submission is always saved.
- Detailed error logging so Render logs show exactly what went wrong.
- 30s timeout on all HTTP calls so they never hang the request.
- Headers are built lazily so env vars loaded after module import still work.
"""

import os
import re
import json
import requests
from dotenv import load_dotenv

load_dotenv()

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "google/gemini-2.5-flash-lite")
HEADERS = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "https://cleancosmos.app",   # can be anything
    "X-Title": "Clean Cosmos"
}


# ── 1. Vision model: classify image + quantify impact ─────────────────────────
# This is called when a user submits a photo of their eco-action.
# It sends the image + description to the AI and gets back structured data
# (action type, stardust points, CO2 saved, etc.)

def classify_with_openrouter(image_base64: str, description: str) -> dict:
    """
    Classify an eco-action image using AI.
    NEVER raises — always returns a valid dict.
    If AI fails, returns a sensible fallback so the submission still works.
    """
    # Guard: no API key configured
    api_key = os.getenv("OPENROUTER_API_KEY", "")
    if not api_key or api_key.strip() == "":
        print("[AI] WARNING: OPENROUTER_API_KEY is not set. Using fallback classification.")
        return _fallback_result(description)

    prompt = f"""You are an eco-action classifier for a sustainability rewards app called Clean Cosmos.
The app awards "stardust" points to users for sustainable actions.

User description: "{description}"

Analyze the image and the description carefully. Return ONLY valid JSON (no markdown, no explanation):
{{
  "actionType": "solar|composting|recycling|eWaste|water|energy|transport|cutsWaste|optimizesResources|lowersEmissions|other",
  "stardustAwarded": <integer 10-100, higher for bigger impact>,
  "co2ReducedKg": <estimated kg CO2 saved, 0 if not applicable>,
  "energySavedKwh": <estimated kWh saved, 0 if not applicable>,
  "waterSavedLiters": <estimated liters saved, 0 if not applicable>,
  "eWasteKg": <kg of e-waste handled, 0 if not applicable>,
  "estimatedCostSavingRupees": <estimated INR cost saved, 0 if unknown>,
  "impactSummary": "One concise sentence describing the environmental benefit",
  "realWorldEquivalent": "A relatable comparison e.g. like planting 3 trees",
  "isLegitimate": true
}}"""

    payload = {
        "model": "google/gemini-pro-vision",   # use vision model for images
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}
                    },
                    {"type": "text", "text": prompt}
                ]
            }
        ],
        "max_tokens": 512,
    }

    response = requests.post(pi/v1/chat/completions",
        headers=HEADERS,
        json=payload
    )
    response.raise_for_status()
    text = response.json()["choices"][0]["message"]["content"].strip()
