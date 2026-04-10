from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials
from dotenv import load_dotenv
import os

# ✅ Initialize Firebase FIRST — before any router/service imports
cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json")
if os.path.exists(cred_path):
    cred = credentials.Certificate(cred_path)
else:
    import json
    # On deployment (Render), we will pass the whole JSON as a string
    cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
    if not cred_json:
        raise Exception("Missing Firebase Credentials! Check FIREBASE_CREDENTIALS_PATH or FIREBASE_CREDENTIALS_JSON")
    cred = credentials.Certificate(json.loads(cred_json))

firebase_admin.initialize_app(cred, {
    "storageBucket": f"{os.getenv('PROJECT_ID', 'ecotrack-hackathon')}.appspot.com"
})

# Import routers AFTER firebase_admin.initialize_app()
from routers import submissions, chatbot, challenges, leaderboard, dashboard, suggestions, auth

app = FastAPI(title="Clean Cosmos API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(submissions.router,  prefix="/submissions",  tags=["Submissions"])
app.include_router(chatbot.router,      prefix="/chatbot",      tags=["EcoGPT"])
app.include_router(challenges.router,   prefix="/challenges",   tags=["Challenges"])
app.include_router(leaderboard.router,  prefix="/leaderboard",  tags=["Leaderboard"])
app.include_router(dashboard.router,    prefix="/dashboard",    tags=["Dashboard"])
app.include_router(suggestions.router,  prefix="/suggestions",  tags=["Suggestions"])

app.include_router(auth.router, prefix="/auth", tags=["Auth"])

@app.get("/")
def root():
    return {"status": "Clean Cosmos API is running 🌌"}