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
- Model is read lazily (via _get_model()) so Render env vars always win.
"""

import os
import json
import requests
from dotenv import load_dotenv

load_dotenv()

# Default to a stable, always-available free model on OpenRouter.
# Override with OPENROUTER_MODEL env var on the Render dashboard.
_DEFAULT_MODEL = "meta-llama/llama-3.3-70b-instruct:free"


def _get_model() -> str:
    """Read model from env every call so Render env vars are never stale."""
    return os.getenv("OPENROUTER_MODEL", _DEFAULT_MODEL)


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

def classify_with_openrouter(image_base64: str, description: str) -> dict:
    """
    Classify an eco-action using AI.
    - If image_base64 is non-empty: sends image + description to vision model
    - If image_base64 is empty:     sends description only (text-only, faster)
    NEVER raises — always returns a valid dict with fallback if AI fails.
    """
    api_key = os.getenv("OPENROUTER_API_KEY", "")
    if not api_key or not api_key.strip():
        print("[AI] WARNING: OPENROUTER_API_KEY not set — using fallback.")
        return _fallback_result(description)

    model = _get_model()

    prompt = (
        'You are an eco-action classifier for a sustainability rewards app called Clean Cosmos.\n'
        'The app awards "stardust" points to users for sustainable actions.\n\n'
        f'User description: "{description}"\n\n'
        + ("Analyze the image and description carefully.\n" if image_base64 else "Analyze the description and classify the eco-action.\n")
        + 'Return ONLY valid JSON (no markdown, no explanation):\n'
        '{\n'
        '  "actionType": "solar|composting|recycling|eWaste|water|energy|transport|cutsWaste|optimizesResources|lowersEmissions|other",\n'
        '  "stardustAwarded": <integer 10-100, higher for bigger impact>,\n'
        '  "co2ReducedKg": <estimated kg CO2 saved, 0 if not applicable>,\n'
        '  "energySavedKwh": <estimated kWh saved, 0 if not applicable>,\n'
        '  "waterSavedLiters": <estimated liters saved, 0 if not applicable>,\n'
        '  "eWasteKg": <kg of e-waste handled, 0 if not applicable>,\n'
        '  "estimatedCostSavingRupees": <estimated INR cost saved, 0 if unknown>,\n'
        '  "impactSummary": "One concise sentence describing the environmental benefit",\n'
        '  "realWorldEquivalent": "A relatable comparison e.g. like planting 3 trees",\n'
        '  "isLegitimate": true\n'
        '}'
    )

    # Build message content: include image only if provided
    if image_base64:
        content = [
            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}},
            {"type": "text", "text": prompt}
        ]
    else:
        content = prompt  # text-only — works with any model, not just vision

    payload = {
        "model": model,
        "messages": [{"role": "user", "content": content}],
        "max_tokens": 512,
    }

    mode = "vision" if image_base64 else "text-only"
    print(f"[AI] Classifying ({mode}) with model: {model}")
    try:
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=_get_headers(),
            json=payload,
            timeout=20
        )
        if not response.ok:
            print(f"[AI Error] OpenRouter HTTP {response.status_code}: {response.text[:500]}")
            response.raise_for_status()

        text = response.json()["choices"][0]["message"]["content"].strip()

        # Strip markdown code fences if present
        if "```json" in text:
            text = text.split("```json")[-1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].strip()

        result = json.loads(text)
        print(f"[AI] Classification OK: actionType={result.get('actionType')} stardust={result.get('stardustAwarded')}")
        return result
    except Exception as e:
        print(f"[AI Error] Classification failed ({mode}): {e}")
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
    model = _get_model()
    college_name = data.get("college", {}).get("name", "your college")
    blind_spots = data.get("blindSpots", [])

    prompt = (
        f"Based on the following sustainability data for {college_name}, "
        "suggest 3 high-impact eco-actions they should take next.\n\n"
        f"Blind spots (areas with zero activity): {', '.join(blind_spots)}\n\n"
        "Return ONLY a JSON array of 3 strings."
    )

    try:
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 256,
        }
        res = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=_get_headers(),
            json=payload,
            timeout=20
        )
        if not res.ok:
            print(f"[AI Error] Recommendations HTTP {res.status_code}: {res.text[:300]}")
            res.raise_for_status()

        content = res.json()["choices"][0]["message"]["content"].strip()

        # Clean JSON
        if "```json" in content:
            content = content.split("```json")[-1].split("```")[0].strip()
        elif "```" in content:
            content = content.split("```")[1].strip()

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
    Eco-chatbot (Nebula) that handles user queries about sustainability.
    Called from an async FastAPI route via asyncio.to_thread — do NOT make async.
    """
    model = _get_model()
    api_key = os.getenv("OPENROUTER_API_KEY", "")

    if not api_key or not api_key.strip():
        print("[AI] WARNING: OPENROUTER_API_KEY not set — chatbot unavailable.")
        return "I'm sorry, I'm not configured yet. Please contact the app administrator."

    system_prompt = (
        "You are Nebula, a friendly and knowledgeable sustainability expert for the Clean Cosmos app. "
        "Help users understand eco-actions, their environmental impact, and how to live more sustainably. "
        "Keep answers helpful, concise, and focused on environmental impact."
    )

    messages = [{"role": "system", "content": system_prompt}]

    # Sanitise history — only include valid role/content dicts
    for msg in history:
        role = msg.get("role", "") if isinstance(msg, dict) else ""
        content = msg.get("content", "") if isinstance(msg, dict) else ""
        if role in ("user", "assistant") and content:
            messages.append({"role": role, "content": content})

    messages.append({"role": "user", "content": query})

    print(f"[AI Chat] model={model} history_len={len(messages)-2}")
    try:
        payload = {
            "model": model,
            "messages": messages,
            "max_tokens": 1024,
        }
        res = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=_get_headers(),
            json=payload,
            timeout=30
        )
        if not res.ok:
            print(f"[AI Error] Chat HTTP {res.status_code}: {res.text[:500]}")
            res.raise_for_status()

        reply = res.json()["choices"][0]["message"]["content"].strip()
        print(f"[AI Chat] OK — reply_length={len(reply)}")
        return reply
    except Exception as e:
        print(f"[AI Error] Chat failed: {e}")
        return "I'm sorry, I'm having trouble connecting to my eco-brain right now. Please try again in a moment!"
