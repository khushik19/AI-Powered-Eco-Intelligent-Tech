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

# Default model — override with OPENROUTER_MODEL env var on Render dashboard.
_DEFAULT_MODEL = "google/gemini-2.5-flash-lite"


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
    - Validates whether the image/description represents a real, legitimate eco-action.
    - Returns isLegitimate=False + rejectionReason if invalid or unrelated.
    - If image_base64 is non-empty: sends image + description to vision model.
    - If image_base64 is empty:     sends description only.
    NEVER raises — always returns a valid dict (fallback if AI errors out).
    Target: < 15 seconds on OpenRouter with gemini-2.5-flash-lite.
    """
    api_key = os.getenv("OPENROUTER_API_KEY", "")
    if not api_key or not api_key.strip():
        print("[AI] WARNING: OPENROUTER_API_KEY not set — using fallback.")
        return _fallback_result(description)

    model = _get_model()

    prompt = (
        'You are a strict eco-action validator for "Clean Cosmos", a sustainability rewards app.\n'
        'Your job is to decide if the submitted action is a REAL, LEGITIMATE eco/sustainability action.\n\n'
        f'User description: "{description}"\n\n'
        + (
            "IMPORTANT: Look at the image carefully.\n"
            "- If the image is blank, blurry, irrelevant, or does NOT show any eco-related activity → REJECT.\n"
            "- If the image clearly shows a real eco-action that matches the description → APPROVE.\n"
            "- Mismatches between image and description → REJECT.\n"
            if image_base64 else
            "No image provided — validate based on description alone.\n"
            "- If the description is vague, fake-sounding, too short, or not an eco-action → REJECT.\n"
            "- If the description clearly describes a real sustainability action → APPROVE.\n"
        )
        + '\nReturn ONLY valid JSON (no markdown, no explanation):\n'
        '{\n'
        '  "isLegitimate": true or false,\n'
        '  "rejectionReason": "Short reason if rejected, else null",\n'
        '  "actionType": "solar|composting|recycling|eWaste|water|energy|transport|cutsWaste|optimizesResources|lowersEmissions|other",\n'
        '  "stardustAwarded": <integer 10-100 based on impact scale, 0 if rejected>,\n'
        '  "co2ReducedKg": <estimated kg CO2 avoided, 0 if not applicable or rejected>,\n'
        '  "energySavedKwh": <estimated kWh saved, 0 if not applicable or rejected>,\n'
        '  "waterSavedLiters": <estimated liters saved, 0 if not applicable or rejected>,\n'
        '  "eWasteKg": <kg e-waste handled, 0 if not applicable or rejected>,\n'
        '  "estimatedCostSavingRupees": <INR saved, 0 if unknown or rejected>,\n'
        '  "impactSummary": "One sentence describing the benefit (or the reason for rejection)",\n'
        '  "realWorldEquivalent": "A relatable analogy e.g. equivalent to planting 2 trees (null if rejected)"\n'
        '}'
    )

    # Build message content
    if image_base64:
        content = [
            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}},
            {"type": "text", "text": prompt}
        ]
    else:
        content = prompt

    payload = {
        "model": model,
        "messages": [{"role": "user", "content": content}],
        "max_tokens": 300,   # Tight limit for speed
        "temperature": 0.2,  # Low randomness for consistent validation
    }

    mode = "vision" if image_base64 else "text-only"
    print(f"[AI] Classifying ({mode}) with model: {model}")
    try:
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=_get_headers(),
            json=payload,
            timeout=25  # 25s hard cap — fast model should respond in 5-10s
        )
        if not response.ok:
            print(f"[AI Error] OpenRouter HTTP {response.status_code}: {response.text[:500]}")
            response.raise_for_status()

        text = response.json()["choices"][0]["message"]["content"].strip()

        # Strip markdown fences
        if "```json" in text:
            text = text.split("```json")[-1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].strip()

        result = json.loads(text)
        legit = result.get("isLegitimate", True)
        print(
            f"[AI] Classification OK: actionType={result.get('actionType')} "
            f"stardust={result.get('stardustAwarded')} legitimate={legit}"
        )
        # Ensure required keys always present
        result.setdefault("rejectionReason", None)
        result.setdefault("isLegitimate", True)
        return result

    except Exception as e:
        print(f"[AI Error] Classification failed ({mode}): {e}")
        return _fallback_result(description)


def _fallback_result(description: str) -> dict:
    """Returned when AI is unavailable — always approves with minimal points."""
    return {
        "isLegitimate": True,
        "rejectionReason": None,
        "actionType": "other",
        "stardustAwarded": 10,
        "co2ReducedKg": 0.2,
        "energySavedKwh": 0.0,
        "waterSavedLiters": 0,
        "eWasteKg": 0,
        "estimatedCostSavingRupees": 0,
        "impactSummary": "Eco-action recorded (AI offline — manual review may apply).",
        "realWorldEquivalent": None,
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


def _call_openrouter_chat(messages: list, model: str, api_key: str) -> str | None:
    """
    Makes a single OpenRouter chat request.
    Returns the reply string on success, None on any failure.
    Logs full error body so Render dashboard shows exactly what went wrong.
    """
    payload = {
        "model": model,
        "messages": messages,
        "max_tokens": 1024,
    }
    try:
        res = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://cleancosmos.web.app",
                "X-Title": "Clean Cosmos",
            },
            json=payload,
            timeout=30,
        )
        if res.ok:
            reply = res.json()["choices"][0]["message"]["content"].strip()
            print(f"[AI Chat] OK model={model} reply_len={len(reply)}")
            return reply
        else:
            print(f"[AI Chat] {model} → HTTP {res.status_code}: {res.text[:400]}")
            return None
    except Exception as e:
        print(f"[AI Chat] {model} → exception: {e}")
        return None


def chat_with_openrouter(query: str, history: list = []) -> str:
    """
    Eco-chatbot (Nebula) that handles user queries about sustainability.
    Called from an async FastAPI route via asyncio.to_thread — do NOT make async.
    Tries preferred model first, falls back to guaranteed-free models on failure.
    """
    api_key = os.getenv("OPENROUTER_API_KEY", "")

    if not api_key or not api_key.strip():
        print("[AI] WARNING: OPENROUTER_API_KEY not set — chatbot unavailable.")
        return "I'm not configured yet. Please set OPENROUTER_API_KEY in the Render environment."

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

    # Model fallback chain: preferred → proven free alternatives
    preferred = _get_model()
    fallback_models = [
        "google/gemma-3-27b-it:free",
        "meta-llama/llama-3.3-70b-instruct:free",
    ]

    # Try preferred model first
    print(f"[AI Chat] Trying preferred model: {preferred}")
    reply = _call_openrouter_chat(messages, preferred, api_key)
    if reply:
        return reply

    # If preferred fails, try fallbacks
    for fb_model in fallback_models:
        if fb_model == preferred:
            continue  # skip if already tried
        print(f"[AI Chat] Preferred failed — trying fallback: {fb_model}")
        reply = _call_openrouter_chat(messages, fb_model, api_key)
        if reply:
            return reply

    print("[AI Chat] All models failed — returning user-friendly error")
    return (
        "I'm having trouble connecting to my eco-brain right now. "
        "This usually means the AI service is temporarily unavailable. "
        "Please try again in a moment!"
    )
