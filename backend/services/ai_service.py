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

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
TIMEOUT = 30  # seconds — Render has a 60s limit; 30s leaves headroom


def _headers() -> dict:
    """Build headers fresh each call so env vars are always up-to-date."""
    key = os.getenv("OPENROUTER_API_KEY", "")
    model = os.getenv("OPENROUTER_MODEL", "google/gemini-2.5-flash-lite")
    return {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://cleancosmos.web.app",
        "X-Title": "Clean Cosmos",
        "_model": model,  # passed around internally, stripped before request
    }


def _get_model() -> str:
    return os.getenv("OPENROUTER_MODEL", "google/gemini-2.5-flash-lite")


def _api_headers() -> dict:
    """HTTP headers only (no internal fields)."""
    key = os.getenv("OPENROUTER_API_KEY", "")
    return {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://cleancosmos.web.app",
        "X-Title": "Clean Cosmos",
    }


# ── Fallback result used when AI classification fails ─────────────────────────
def _fallback_result(description: str) -> dict:
    """
    Safe default returned when AI is unavailable.
    Submission is still recorded; user still earns stardust.
    Category is guessed from keywords in the description.
    """
    desc_lower = description.lower()
    action_map = {
        "solar": ["solar", "panel", "photovoltaic"],
        "recycling": ["recycle", "recycling", "plastic", "glass", "paper", "tin"],
        "composting": ["compost", "compost", "organic", "food waste"],
        "eWaste": ["ewaste", "e-waste", "electronic", "phone", "battery", "computer"],
        "water": ["water", "rain", "harvest", "drip", "irrigat"],
        "energy": ["energy", "electricity", "led", "light", "bulb", "power"],
        "transport": ["cycle", "bike", "walk", "carpool", "bus", "electric vehicle", "ev"],
        "cutsWaste": ["waste", "single use", "plastic bag", "straw", "packaging"],
    }
    action_type = "other"
    for cat, keywords in action_map.items():
        if any(k in desc_lower for k in keywords):
            action_type = cat
            break

    return {
        "actionType": action_type,
        "stardustAwarded": 25,
        "co2ReducedKg": 0.5,
        "energySavedKwh": 0,
        "waterSavedLiters": 0,
        "eWasteKg": 0,
        "estimatedCostSavingRupees": 0,
        "impactSummary": "Great eco action! Keep up the sustainable habits.",
        "realWorldEquivalent": "Equivalent to saving a small tree over a year.",
        "isLegitimate": True,
        "aiClassified": False,         # flag so you know it was a fallback
    }


def _parse_json_from_text(text: str) -> dict:
    """
    Robust JSON extractor — handles:
    - Clean JSON
    - Markdown fences (```json ... ```)
    - JSON embedded in prose
    - Trailing commas (best-effort)
    """
    # Remove markdown fences
    text = re.sub(r"```json\s*", "", text)
    text = re.sub(r"```\s*", "", text)
    text = text.strip()

    # Try direct parse first
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Extract first {...} block
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        candidate = match.group(0)
        # Remove trailing commas before } or ] (common LLM mistake)
        candidate = re.sub(r",\s*([}\]])", r"\1", candidate)
        try:
            return json.loads(candidate)
        except json.JSONDecodeError:
            pass

    raise ValueError(f"No valid JSON found in response:\n{text[:300]}")


# ── 1. Image Classification ────────────────────────────────────────────────────

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
        "model": _get_model(),
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

    try:
        response = requests.post(
            OPENROUTER_URL,
            headers=_api_headers(),
            json=payload,
            timeout=TIMEOUT
        )

        if not response.ok:
            err = response.text[:300]
            print(f"[AI] Classification HTTP error {response.status_code}: {err}")
            # 401 = bad/revoked key, 402 = out of credits, 429 = rate limit
            return _fallback_result(description)

        data = response.json()

        # Validate expected response shape
        if "choices" not in data or not data["choices"]:
            print(f"[AI] Unexpected response shape: {str(data)[:200]}")
            return _fallback_result(description)

        text = data["choices"][0]["message"]["content"].strip()
        print(f"[AI] Raw response: {text[:200]}")

        result = _parse_json_from_text(text)
        result["aiClassified"] = True
        return result

    except requests.Timeout:
        print(f"[AI] Classification timed out after {TIMEOUT}s — using fallback.")
        return _fallback_result(description)

    except Exception as e:
        print(f"[AI] Classification failed with unexpected error: {e}")
        return _fallback_result(description)


# ── 2. EcoGPT Chatbot ─────────────────────────────────────────────────────────

def chat_with_openrouter(query: str, history: list) -> str:
    """Returns a chatbot response. Raises on error (chatbot should show error to user)."""
    api_key = os.getenv("OPENROUTER_API_KEY", "")
    if not api_key:
        raise ValueError("OPENROUTER_API_KEY not configured on server.")

    messages = [
        {
            "role": "system",
            "content": (
                "You are EcoGPT, the sustainability assistant for Clean Cosmos — "
                "an app that rewards students and institutions for eco-friendly actions with 'stardust' points.\n"
                "Help users with: recycling, energy saving, composting, e-waste, water conservation, "
                "sustainable campus practices, and earning stardust points.\n"
                "Be concise, factual, practical, and encouraging. Give specific actionable steps."
            ),
        }
    ]
    for msg in history:
        messages.append({"role": msg.get("role", "user"), "content": msg.get("content", "")})
    messages.append({"role": "user", "content": query})

    response = requests.post(
        OPENROUTER_URL,
        headers=_api_headers(),
        json={"model": _get_model(), "messages": messages, "max_tokens": 600},
        timeout=TIMEOUT,
    )

    if not response.ok:
        print(f"[AI] Chatbot HTTP error {response.status_code}: {response.text[:200]}")
        response.raise_for_status()

    return response.json()["choices"][0]["message"]["content"]


# ── 3. College Recommendations ────────────────────────────────────────────────

def get_recommendations(college_data: dict) -> list:
    """Returns 3 sustainability recommendations for a college. Returns empty list on failure."""
    try:
        api_key = os.getenv("OPENROUTER_API_KEY", "")
        if not api_key:
            return []

        prompt = f"""A college is using the Clean Cosmos sustainability app. Profile:
{json.dumps(college_data, indent=2)}

Suggest exactly 3 high-impact sustainability actions based on their blind spots.
Return ONLY a JSON array (no markdown):
[
  {{"title": "...", "reason": "...", "estimatedImpact": "...", "difficulty": "easy|medium|hard", "stardustEstimate": <10-100>}},
  {{"title": "...", "reason": "...", "estimatedImpact": "...", "difficulty": "easy|medium|hard", "stardustEstimate": <10-100>}},
  {{"title": "...", "reason": "...", "estimatedImpact": "...", "difficulty": "easy|medium|hard", "stardustEstimate": <10-100>}}
]"""

        response = requests.post(
            OPENROUTER_URL,
            headers=_api_headers(),
            json={"model": _get_model(), "messages": [{"role": "user", "content": prompt}], "max_tokens": 600},
            timeout=TIMEOUT,
        )
        if not response.ok:
            return []

        text = response.json()["choices"][0]["message"]["content"].strip()
        text = re.sub(r"```json\s*", "", text)
        text = re.sub(r"```\s*", "", text).strip()
        return json.loads(text)

    except Exception as e:
        print(f"[AI] Recommendations failed: {e}")
        return []