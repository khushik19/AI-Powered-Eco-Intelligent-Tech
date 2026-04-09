from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import submissions, chatbot, challenges, leaderboard
import firebase_admin
from firebase_admin import credentials
from dotenv import load_dotenv
import os

load_dotenv()

# Initialize Firebase Admin
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH"))
firebase_admin.initialize_app(cred, {
    "storageBucket": "your-project-id.appspot.com"  # replace with yours
})

app = FastAPI(title="EcoTrack API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten in production
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(submissions.router, prefix="/submissions", tags=["Submissions"])
app.include_router(chatbot.router, prefix="/chatbot", tags=["Chatbot"])
app.include_router(challenges.router, prefix="/challenges", tags=["Challenges"])
app.include_router(leaderboard.router, prefix="/leaderboard", tags=["Leaderboard"])

@app.get("/")
def root():
    return {"status": "EcoTrack API is running"}