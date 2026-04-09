import os
import json
import base64
import requests
from google import genai
from google.genai import errors as genai_errors
from dotenv import load_dotenv

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# gemini-2.0-flash-lite — available on this key, free tier friendly
MODEL = "gemini-2.0-flash-lite"


def classify_with_gemini(image_base64: str, description: str) -> dict:
    """Analyzes an eco-action image. Returns structured JSON dict."""
    prompt = f"""You are an eco-action classifier for a sustainability platform.
User description: {description}

Look at this image and respond ONLY with valid JSON (no markdown, no code blocks):
{{
  "actionType": "solar|composting|recycling|eWaste|water|energy|other",
  "pointsAwarded": <integer between 10 and 100>,
  "impactSummary": "One sentence describing the environmental impact",
  "realWorldEquivalent": "e.g. equivalent to planting 3 trees",
  "isLegitimate": true
}}

If the image is NOT related to an eco-action, set isLegitimate to false and pointsAwarded to 0."""

    image_data = base64.b64decode(image_base64)

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=[
                prompt,
                {"mime_type": "image/jpeg", "data": image_data}
            ]
        )
    except genai_errors.ClientError as e:
        if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
            raise RuntimeError("Gemini API rate limit reached. Please wait a moment and try again.")
        raise RuntimeError(f"Gemini API error: {str(e)}")

    raw = response.text.strip()
    # Strip markdown fences if model wraps the output
    if raw.startswith("```"):
        parts = raw.split("```")
        raw = parts[1] if len(parts) > 1 else raw
        if raw.startswith("json"):
            raw = raw[4:]

    try:
        return json.loads(raw.strip())
    except json.JSONDecodeError:
        raise RuntimeError(f"Gemini returned non-JSON response: {raw[:200]}")


def chat_with_gemini(query: str, history: list) -> str:
    """EcoGPT chatbot with conversation history."""
    system = (
        "You are EcoGPT, an expert sustainability assistant for college campuses. "
        "Answer questions about recycling, energy saving, composting, e-waste, "
        "water conservation, and any eco-related topic. Be concise, factual, and actionable."
    )

    # Build a single string conversation
    contents = [system]
    for m in history:
        role = "User" if m.get("role") == "user" else "EcoGPT"
        contents.append(f"{role}: {m.get('content', '')}")
    contents.append(f"User: {query}")
    contents.append("EcoGPT:")

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents="\n".join(contents)
        )
        return response.text.strip()
    except genai_errors.ClientError as e:
        if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
            raise RuntimeError("Gemini API rate limit reached. Please wait a moment and try again.")
        raise RuntimeError(f"Gemini API error: {str(e)}")


# ─── OpenRouter (optional fallback) ──────────────────────────────
def chat_with_openrouter(query: str, history: list) -> str:
    messages = [
        {"role": "system", "content": "You are an expert sustainability assistant for college campuses."}
    ] + [{"role": m["role"], "content": m["content"]} for m in history] + [
        {"role": "user", "content": query}
    ]

    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {os.getenv('OPENROUTER_API_KEY')}",
            "Content-Type": "application/json"
        },
        json={
            "model": os.getenv("OPENROUTER_MODEL", "google/gemini-2.0-flash-exp"),
            "messages": messages
        }
    )
    return response.json()["choices"][0]["message"]["content"]