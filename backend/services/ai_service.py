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

OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "google/gemini-2.0-flash-exp:free")


def _get_headers() -> dict:
    """Build headers lazily so env vars are always read fresh."""
    api_key = os.getenv("OPENROUTER_API_KEY", "")
    return {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://cleancosmos.app",
        "X-Title": "Clean Cosmos",
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
    if not api_key or not api_key.strip():
        print("[AI] WARNING: OPENROUTER_API_KEY not set — using fallback.")
        return _fallback_result(description)

    model = os.getenv("OPENROUTER_MODEL", "google/gemini-2.0-flash-exp:free")

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
        "model": model,   # vision-capable model from env (e.g. google/gemini-2.0-flash-exp:free)
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

    print(f"[AI] Classifying with model: {model}")
    try:
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=_get_headers(),
            json=payload,
            timeout=25
        )
        response.raise_for_status()
        text = response.json()["choices"][0]["message"]["content"].strip()

        # Extract JSON from markdown if necessary
        if "```json" in text:
            text = text.split("```json")[-1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[-1].split("```")[0].strip()

        return json.loads(text)
    except Exception as e:
        print(f"[AI Error] Classification failed: {e}")
        return _fallback_result(description)


def _fallback_result(description: str) -> dict:
    """Sensible default metrics when AI fails."""
    return {
        "actionType": "other",
        "stardustAwarded": 20,
        "co2ReducedKg": 0.5,
        "energySavedKwh": 0.1,
        "waterSavedLiters": 0,
        "eWasteKg": 0,
        "estimatedCostSavingRupees": 5,
        "impactSummary": "Successfully logged your eco-action!",
        "realWorldEquivalent": "Keeping the planet a bit cleaner",
        "isLegitimate": True
    }


def get_recommendations(data: dict) -> list:
    """
    Analyzes college dashboard data and returns AI-generated suggestions.
    """
    college_name = data.get("college", {}).get("name", "your college")
    blind_spots = data.get("blindSpots", [])
    
    prompt = f"""Based on the following sustainability data for {college_name}, 
    suggest 3 high-impact eco-actions they should take next.
    
    Blind spots (areas with zero activity): {", ".join(blind_spots)}
    
    Return ONLY a JSON list of strings."""

    try:
        payload = {
            "model": OPENROUTER_MODEL,
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 256,
        }
        res = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=_get_headers(),
            json=payload,
            timeout=20
        )
        res.raise_for_status()
        content = res.json()["choices"][0]["message"]["content"].strip()
        
        # Clean JSON
        if "```json" in content:
            content = content.split("```json")[-1].split("```")[0].strip()
        
        return json.loads(content)
    except Exception as e:
        print(f"[AI Error] Recommendations failed: {e}")
        return [
            "Start a campus-wide recycling drive",
            "Install solar-powered lighting in common areas",
            "Implement a rainwater harvesting system"
        ]


def chat_with_openrouter(query: str, history: list = []) -> str:
    """
    Eco-chatbot that handles user queries about sustainability.
    """
    system_prompt = (
        "You are EcoGPT, a friendly sustainability expert for the Clean Cosmos app. "
        "Keep your answers helpful, concise, and focused on environmental impact."
    )
    
    messages = [{"role": "system", "content": system_prompt}]
    for msg in history:
        messages.append(msg)
    messages.append({"role": "user", "content": query})

    try:
        payload = {
            "model": OPENROUTER_MODEL,
            "messages": messages,
            "max_tokens": 1024,
        }
        res = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=_get_headers(),
            json=payload,
            timeout=30
        )
        res.raise_for_status()
        return res.json()["choices"][0]["message"]["content"].strip()
    except Exception as e:
        print(f"[AI Error] Chat failed: {e}")
        return "I'm sorry, I'm having trouble connecting to my eco-brain right now. Try again later!"
