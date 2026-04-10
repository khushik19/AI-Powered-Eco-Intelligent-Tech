import os
import json
import requests
import base64
from dotenv import load_dotenv

load_dotenv()

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "google/gemini-2.5-flash-lite")
HEADERS = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "https://cleancosmos.app",   
    "X-Title": "Clean Cosmos"
}



def classify_with_openrouter(image_base64: str, description: str) -> dict:
    prompt = f"""You are an eco-action classifier for a sustainability rewards app called Clean Cosmos.
The app awards "stardust" points to users for sustainable actions.

User description: "{description}"

Analyze the image and the description carefully. Return ONLY valid JSON with no markdown, no explanation, nothing else:
{{
  "actionType": "solar|composting|recycling|eWaste|water|energy|transport|cutsWaste|optimizesResources|lowersEmissions|other",
  "stardustAwarded": <integer between 10 and 100, higher for bigger environmental impact>,
  "co2ReducedKg": <estimated kg of CO2 saved, use 0 if not applicable>,
  "energySavedKwh": <estimated kWh of energy saved, use 0 if not applicable>,
  "waterSavedLiters": <estimated liters of water saved, use 0 if not applicable>,
  "eWasteKg": <kg of e-waste properly handled, use 0 if not applicable>,
  "estimatedCostSavingRupees": <estimated INR cost saved, use 0 if unknown>,
  "impactSummary": "One clear sentence describing the environmental benefit of this action",
  "realWorldEquivalent": "A relatable comparison e.g. equivalent to planting 4 trees or saving 500 plastic bottles",
  "isLegitimate": true
}}

Base your estimates on real environmental benchmarks. Be generous but realistic with stardust points."""

    payload = {
        "model": "google/gemini-pro-vision",   
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{image_base64}"
                        }
                    },
                    {
                        "type": "text",
                        "text": prompt
                    }
                ]
            }
        ],
        "max_tokens": 500
    }

    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers=HEADERS,
        json=payload
    )
    response.raise_for_status()
    text = response.json()["choices"][0]["message"]["content"].strip()
    text = text.replace("```json", "").replace("```", "").strip()
    return json.loads(text)



def chat_with_openrouter(query: str, history: list) -> str:
    system_message = {
        "role": "system",
        "content": """You are Nebula, the sustainability chatbot assistant for Clean Cosmos — 
an app that rewards students and institutions for sustainable actions with "stardust" points.
You help users with: recycling methods, energy saving tips, composting guides, e-waste disposal, a
water conservation, sustainable campus practices, and how to earn more stardust points.
Always be concise, factual, practical, and encouraging while also being fun. 
Suggest specific actionable steps. When relevant, mention how the action could earn stardust points."""
    }

    
    messages = [system_message]
    for msg in history:
        messages.append({
            "role": msg["role"],  
            "content": msg["content"]
        })
    messages.append({"role": "user", "content": query})

    payload = {
        "model": OPENROUTER_MODEL,
        "messages": messages,
        "max_tokens": 600
    }

    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers=HEADERS,
        json=payload
    )
    if not response.ok:
        print(f"[OpenRouter ERROR] Status {response.status_code}: {response.text}")
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"]



def get_recommendations(college_data: dict) -> list:
    prompt = f"""A college is using the Clean Cosmos sustainability app. Here is their current profile:
{json.dumps(college_data, indent=2)}

Based on their action history and blind spots (categories with zero activity), 
suggest exactly 3 high-impact sustainability actions they should try next.
Return ONLY a JSON array with no markdown:
[
  {{
    "title": "Short action title",
    "reason": "Why this is important for their specific situation",
    "estimatedImpact": "Specific impact e.g. could save 500kg CO2/month",
    "difficulty": "easy|medium|hard",
    "stardustEstimate": <estimated stardust points 10-100>
  }},
  {{
    "title": "...",
    "reason": "...",
    "estimatedImpact": "...",
    "difficulty": "easy|medium|hard",
    "stardustEstimate": <integer>
  }},
  {{
    "title": "...",
    "reason": "...",
    "estimatedImpact": "...",
    "difficulty": "easy|medium|hard",
    "stardustEstimate": <integer>
  }}
]"""

    payload = {
        "model": OPENROUTER_MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 600
    }

    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers=HEADERS,
        json=payload
    )
    response.raise_for_status()
    text = response.json()["choices"][0]["message"]["content"].strip()
    text = text.replace("```json", "").replace("```", "").strip()
    return json.loads(text)