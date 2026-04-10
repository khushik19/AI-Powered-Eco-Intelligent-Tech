import os
import json
from dotenv import load_dotenv

# ── Load env FIRST before anything else ───────────────────────────────────────
load_dotenv()

import firebase_admin
from firebase_admin import credentials

# ── Initialize Firebase Admin ──────────────────────────────────────────────────
if not firebase_admin._apps:
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "serviceAccountKey.json")
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
    else:
        cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
        if not cred_json:
            raise RuntimeError(
                "Firebase credentials missing! Set FIREBASE_CREDENTIALS_JSON env var on Render."
            )
        cred_dict = json.loads(cred_json)
        # Fix escaped newlines in private_key (common issue when pasting JSON into Render Env Vars)
        if "private_key" in cred_dict:
            cred_dict["private_key"] = cred_dict["private_key"].replace("\\n", "\n")
            
        cred = credentials.Certificate(cred_dict)

    project_id = os.getenv("PROJECT_ID", "ecotrack-hackathon")
    firebase_admin.initialize_app(cred, {
        "storageBucket": f"{project_id}.appspot.com",
        "projectId": project_id,
    })

# ── Import routers AFTER Firebase is initialized ───────────────────────────────
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import submissions, chatbot, challenges, leaderboard, dashboard, suggestions, auth

load_dotenv()

# Initialize Firebase with your service account key
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH"))
firebase_admin.initialize_app(cred, {
    "storageBucket": f"{os.getenv('PROJECT_ID')}.appspot.com"
})

# Import routers AFTER firebase_admin.initialize_app
from routers import submissions, chatbot, challenges, leaderboard, dashboard, suggestions

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
app.include_router(auth.router,         prefix="/auth",         tags=["Auth"])


@app.get("/")