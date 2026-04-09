"""
Run this ONCE to populate Firestore with demo data.
Command: python seed.py
"""
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
import os
from datetime import datetime, timedelta
import random

load_dotenv()
cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH"))
firebase_admin.initialize_app(cred)
db = firestore.client()

print("Seeding Clean Cosmos database...")

# ── Predefined actions (shown in the app as preset options) ───────────────────
predefined_actions = [
    {
        "title": "Install Solar Panels",
        "category": "energy", "targetRole": "college",
        "description": "Install photovoltaic solar panels on rooftop or open areas",
        "baseStardust": 90, "estimatedCo2Kg": 580, "estimatedEnergyKwh": 1200,
        "iconName": "solar_power"
    },
    {
        "title": "Start Composting Program",
        "category": "cutsWaste", "targetRole": "both",
        "description": "Compost food and organic waste from canteen or cafeteria",
        "baseStardust": 60, "estimatedCo2Kg": 85, "estimatedEnergyKwh": 0,
        "iconName": "compost"
    },
    {
        "title": "E-Waste Collection Drive",
        "category": "eWaste", "targetRole": "college",
        "description": "Organise a campus-wide e-waste collection and proper disposal event",
        "baseStardust": 75, "estimatedCo2Kg": 120, "estimatedEnergyKwh": 200,
        "iconName": "devices"
    },
    {
        "title": "Cycle to College",
        "category": "transport", "targetRole": "student",
        "description": "Commute to college by bicycle instead of motorised transport",
        "baseStardust": 20, "estimatedCo2Kg": 2.3, "estimatedEnergyKwh": 0,
        "iconName": "directions_bike"
    },
    {
        "title": "Use Reusable Water Bottle",
        "category": "cutsWaste", "targetRole": "student",
        "description": "Replace single-use plastic bottles with a reusable bottle for a week",
        "baseStardust": 15, "estimatedCo2Kg": 0.5, "estimatedEnergyKwh": 0,
        "iconName": "water_drop"
    },
    {
        "title": "Switch to LED Lighting",
        "category": "energy", "targetRole": "college",
        "description": "Replace all fluorescent and incandescent bulbs with LED fixtures",
        "baseStardust": 65, "estimatedCo2Kg": 180, "estimatedEnergyKwh": 860,
        "iconName": "bolt"
    },
    {
        "title": "Rainwater Harvesting System",
        "category": "water", "targetRole": "college",
        "description": "Install rainwater collection and filtration infrastructure",
        "baseStardust": 80, "estimatedCo2Kg": 40, "estimatedEnergyKwh": 80,
        "iconName": "water"
    },
    {
        "title": "Paper Recycling Drive",
        "category": "recycling", "targetRole": "both",
        "description": "Collect and send old documents, newspapers, and paper waste for recycling",
        "baseStardust": 30, "estimatedCo2Kg": 25, "estimatedEnergyKwh": 50,
        "iconName": "recycling"
    },
]

for action in predefined_actions:
    db.collection("predefined_actions").add(action)
print(f"  Added {len(predefined_actions)} predefined actions")

# ── Demo colleges ─────────────────────────────────────────────────────────────
colleges = [
    {
        "id": "college_manipal",
        "name": "MIT Manipal", "city": "Manipal", "state": "Karnataka",
        "email": "admin@manipal.edu",
        "totalStardust": 7200, "accreditationScore": 720,
        "accreditationTier": "gold",
        "totalCo2Kg": 5800, "totalEnergySavedKwh": 14200,
        "totalWaterSavedL": 92000, "totalEWasteKg": 340,
        "studentCount": 10, "createdAt": datetime.utcnow().isoformat()
    },
    {
        "id": "college_vit",
        "name": "VIT Vellore", "city": "Vellore", "state": "Tamil Nadu",
        "email": "admin@vit.ac.in",
        "totalStardust": 4800, "accreditationScore": 480,
        "accreditationTier": "silver",
        "totalCo2Kg": 2340, "totalEnergySavedKwh": 8600,
        "totalWaterSavedL": 45000, "totalEWasteKg": 180,
        "studentCount": 8, "createdAt": datetime.utcnow().isoformat()
    },
    {
        "id": "college_bits",
        "name": "BITS Pilani", "city": "Pilani", "state": "Rajasthan",
        "email": "admin@bits.ac.in",
        "totalStardust": 2100, "accreditationScore": 210,
        "accreditationTier": "silver",
        "totalCo2Kg": 980, "totalEnergySavedKwh": 3100,
        "totalWaterSavedL": 18000, "totalEWasteKg": 90,
        "studentCount": 6, "createdAt": datetime.utcnow().isoformat()
    },
]

for college in colleges:
    college_id = college.pop("id")
    db.collection("colleges").document(college_id).set(college)
print(f"  Added {len(colleges)} demo colleges")

# ── Demo students ─────────────────────────────────────────────────────────────
students = [
    {"id": "student_aryan",  "name": "Aryan Sharma",  "collegeId": "college_manipal", "stardust": 340, "currentStreak": 7},
    {"id": "student_priya",  "name": "Priya Nair",    "collegeId": "college_manipal", "stardust": 210, "currentStreak": 4},
    {"id": "student_rohit",  "name": "Rohit Verma",   "collegeId": "college_manipal", "stardust": 180, "currentStreak": 2},
    {"id": "student_sana",   "name": "Sana Iyer",     "collegeId": "college_vit",     "stardust": 290, "currentStreak": 5},
    {"id": "student_karan",  "name": "Karan Mehta",   "collegeId": "college_vit",     "stardust": 120, "currentStreak": 1},
    {"id": "student_divya",  "name": "Divya Pillai",  "collegeId": "college_bits",    "stardust": 160, "currentStreak": 3},
]

for student in students:
    sid = student.pop("id")
    db.collection("users").document(sid).set({
        **student,
        "role": "student", "totalActions": random.randint(5, 20),
        "email": f"{sid}@demo.com",
        "lastActionDate": (datetime.utcnow() - timedelta(hours=random.randint(1, 20))).isoformat(),
        "createdAt": datetime.utcnow().isoformat()
    })
print(f"  Added {len(students)} demo students")

# ── Demo submissions ───────────────────────────────────────────────────────────
action_templates = [
    {"actionType": "solar",      "description": "Installed solar panels on hostel rooftop",
     "stardustAwarded": 90, "co2ReducedKg": 580, "energySavedKwh": 1200, "waterSavedLiters": 0, "eWasteKg": 0,
     "impactSummary": "Solar panels reduce grid dependency and cut carbon emissions significantly.",
     "realWorldEquivalent": "equivalent to planting 26 trees", "collegeId": "college_manipal"},

    {"actionType": "transport",  "description": "Cycling to college instead of using motorbike",
     "stardustAwarded": 25, "co2ReducedKg": 2.3, "energySavedKwh": 0, "waterSavedLiters": 0, "eWasteKg": 0,
     "impactSummary": "Cycling eliminates daily commute emissions.",
     "realWorldEquivalent": "equivalent to saving 1L of petrol", "collegeId": "college_manipal"},

    {"actionType": "water",      "description": "Installed rainwater harvesting system near labs",
     "stardustAwarded": 65, "co2ReducedKg": 40, "energySavedKwh": 80, "waterSavedLiters": 12000, "eWasteKg": 0,
     "impactSummary": "Rainwater harvesting reduces dependence on municipal water supply.",
     "realWorldEquivalent": "equivalent to 48,000 bottles of water saved", "collegeId": "college_vit"},

    {"actionType": "recycling",  "description": "Organized paper recycling drive in admin block",
     "stardustAwarded": 40, "co2ReducedKg": 25, "energySavedKwh": 50, "waterSavedLiters": 0, "eWasteKg": 0,
     "impactSummary": "Paper recycling saves trees and reduces landfill waste.",
     "realWorldEquivalent": "equivalent to saving 2 trees", "collegeId": "college_vit"},

    {"actionType": "energy",     "description": "Replaced all corridor lights with LED fixtures",
     "stardustAwarded": 60, "co2ReducedKg": 180, "energySavedKwh": 860, "waterSavedLiters": 0, "eWasteKg": 0,
     "impactSummary": "LED upgrades cut lighting energy consumption by up to 75%.",
     "realWorldEquivalent": "equivalent to powering 3 homes for a month", "collegeId": "college_bits"},
]

student_ids = ["student_aryan", "student_priya", "student_rohit", "student_sana", "student_karan", "student_divya"]

for i, template in enumerate(action_templates):
    for j in range(random.randint(2, 5)):
        days_ago = random.randint(1, 90)
        submission_date = (datetime.utcnow() - timedelta(days=days_ago)).isoformat()
        college_id = template.pop("collegeId") if "collegeId" in template else "college_manipal"
        user_id = random.choice([s for s in student_ids if
                                  db.collection("users").document(s).get().to_dict().get("collegeId") == college_id]
                                 or student_ids)
        db.collection("submissions").add({
            **template,
            "userId": user_id,
            "collegeId": college_id,
            "role": "student",
            "isPredefined": False,
            "imageUrl": "",
            "status": "approved",
            "estimatedCostSavingRupees": random.randint(500, 10000),
            "createdAt": submission_date
        })
        template["collegeId"] = college_id

print(f"  Added demo submissions")

# ── Demo challenges ────────────────────────────────────────────────────────────
challenges = [
    {
        "title": "Zero Plastic Week",
        "description": "Go an entire week without using single-use plastic. Document your alternatives.",
        "pointReward": 50, "targetRole": "student",
        "collegeId": None, "isActive": True,
        "deadline": (datetime.utcnow() + timedelta(days=7)).isoformat(),
        "createdAt": datetime.utcnow().isoformat()
    },
    {
        "title": "Energy Audit Challenge",
        "description": "Identify and report 5 energy wastage points on your campus.",
        "pointReward": 75, "targetRole": "both",
        "collegeId": None, "isActive": True,
        "deadline": (datetime.utcnow() + timedelta(days=14)).isoformat(),
        "createdAt": datetime.utcnow().isoformat()
    },
    {
        "title": "Green Commute Month",
        "description": "Use only non-motorised or public transport for 30 days.",
        "pointReward": 100, "targetRole": "student",
        "collegeId": None, "isActive": True,
        "deadline": (datetime.utcnow() + timedelta(days=30)).isoformat(),
        "createdAt": datetime.utcnow().isoformat()
    },
]

for challenge in challenges:
    db.collection("challenges").add(challenge)
print(f"  Added {len(challenges)} challenges")

print("\nDone! Clean Cosmos database is seeded.")