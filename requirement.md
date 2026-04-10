As Person 3 (The Foundation), you are the architect and the glue. If you fail, the app has no memory; if you succeed, the app feels "live" and intelligent. You own the Database, Cloud Storage, Data Analytics, and Deployment.

Here is your step-by-step battle plan for the next 36 hours.

🛠️ Step 1: Immediate Setup (The First 2 Hours)
Before the clock starts, you must ensure the infrastructure is ready for Person A (Frontend) and Person B (Backend) to connect to.

Firebase Console Setup:

Project: Create "EcoTrack-AI".

Auth: Enable Email/Password.

Firestore: Enable Test Mode. Create a collection called colleges. Add one document manually so the backend can "find" it.

Storage: Enable Test Mode. Create a folder called submissions.

Generate Service Account Key:

Go to Project Settings > Service Accounts > Generate New Private Key.

Action: Rename this to serviceAccountKey.json and give it to Person B immediately. They cannot talk to the database without this.

Local Environment:

Install the Firebase CLI: npm install -g firebase-tools.

Login: firebase login.

🗄️ Step 2: The "Data-Driven" Schema (Hours 2–6)
While your teammates start coding, you are the "Data Entry" specialist. You need to structure Firestore so Person B knows where to send data.

Create these Collections in the Console:

colleges: Fields: name, accreditationTier (String), totalPoints (Number), totalCo2Kg (Number).

users: Fields: name, role (student/college_admin), points, collegeId.

submissions: (This will be populated by the AI).

predefined_actions: Crucial! Manually add 5 docs here:

Doc 1: { "title": "LED Retrofitting", "category": "energy", "basePoints": 50 }

Doc 2: { "title": "Campus Composting", "category": "waste", "basePoints": 40 }

📈 Step 3: Analytics & Benchmarking (Hours 6–18)
This is where you make the app "Data Driven." You need to write the logic (either in the firebase_service.py for Person B or as standalone scripts) that aggregates numbers.

Aggregator Logic:
Write a function that calculates the "College Total."

Sum all co2ReducedKg from the submissions collection where collegeId == X.

Update the colleges document with this total.

Benchmarking Data:
Create a collection called benchmarks. Add a doc:

{ "avgCollegeCo2": 500, "avgStudentWaste": 15 }

Why? Person A will use this to show a "You are performing 20% better than other colleges" UI.

Streak Logic:
Write the logic that checks the lastActionDate in the User doc. If currentDate - lastActionDate == 1 day, increment streak.

🌐 Step 4: DevOps & Deployment (Hours 18–30)
You are responsible for making the app accessible via a URL so the judges can see it on their own phones/laptops.

Deploy Backend (Railway/Render):

Connect the GitHub repo to Railway.

Set the root directory to /backend.

Environment Variables: Add GEMINI_API_KEY and your Firebase credentials.

Give the generated URL (e.g., https://ecotrack-api.up.railway.app) to Person A.

Deploy Frontend (Firebase Hosting):

In the frontend folder, run: flutter build web.

Run firebase init hosting.

Public directory: build/web.

Run firebase deploy.

🧹 Step 5: The "Golden" Seed (Hours 30–34)
Most Important Step. A data-driven app looks terrible if it's empty. You must spend 2 hours "playing" as 20 different users.

Upload 20 fake submissions via the API/App.

Use different images so the charts in the dashboard look "wavy" and interesting.

Ensure one college is "Platinum Tier" and one is "Silver Tier" for the leaderboard demo.