import os
import json
import requests
from dotenv import load_dotenv

load_dotenv()

# ─── Gemini ────────────────────────────────────────────────
def classify_with_gemini(image_base64: str, description: str) -> dict:
    import google.generativeai as genai
    import base64

    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    model = genai.GenerativeModel("gemini-2.0-flash")

    image_data = base64.b64decode(image_base64)
    image_part = {"mime_type": "image/jpeg", "data": image_data}

    prompt = f"""You are an eco-action classifier for a sustainability platform.
User description: {description}

Look at this image and respond ONLY with valid JSON, no markdown:
{{
  "actionType": "solar|composting|recycling|eWaste|water|energy|other",
  "pointsAwarded": <integer between 10 and 100>,
  "impactSummary": "One sentence describing the environmental impact",
  "realWorldEquivalent": "e.g. equivalent to planting 3 trees",
  "isLegitimate": true
}}"""

    response = model.generate_content([prompt, image_part])
    return json.loads(response.text)


def chat_with_gemini(query: str, history: list) -> str:
    import google.generativeai as genai

    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    model = genai.GenerativeModel(
        "gemini-2.0-flash",
        system_instruction="""You are an expert sustainability assistant for college campuses.
Answer questions about recycling, energy saving, composting, e-waste, water conservation,
and any eco-related topic. Be concise, factual, and actionable."""
    )

    chat = model.start_chat(history=[
        {"role": m["role"], "parts": [m["content"]]} for m in history
    ])
    response = chat.send_message(query)
    return response.text


# ─── OpenRouter (alternative) ──────────────────────────────
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