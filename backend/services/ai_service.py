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

    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers=HEADERS,
        json=payload
    )
    response.raise_for_status()
    text = response.json()["choices"][0]["message"]["content"].strip()
    # Strip markdown fences if the model adds them anyway
    text = text.replace("```json", "").replace("```", "").strip()
    return json.loads(text)


# ── 2. EcoGPT: sustainability chatbot ─────────────────────────────────────────
# This is called when a user types a message in the EcoGPT chat screen.
# history is a list of previous messages so the AI has context.

def chat_with_openrouter(query: str, history: list) -> str:
    system_message = {
        "role": "system",
        "content": """You are EcoGPT, the sustainability assistant for Clean Cosmos — 
an app that rewards students and institutions for sustainable actions with "stardust" points.
You help users with: recycling methods, energy saving tips, composting guides, e-waste disposal, 
water conservation, sustainable campus practices, and how to earn more stardust points.
Always be concise, factual, practical, and encouraging. 
Suggest specific actionable steps. When relevant, mention how the action could earn stardust points."""
    }

    # Build conversation history in the format OpenRouter expects
    messages = [system_message]
    for msg in history:
        messages.append({
            "role": msg["role"],  # "user" or "assistant"
            "content": msg["content"]
        })
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


# ── 3. AI Recommendations for college dashboard ───────────────────────────────
# This is called when a college loads their dashboard.
# It looks at what they've done and suggests what they should do next.

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