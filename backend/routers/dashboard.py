from fastapi import APIRouter
from firebase_admin import firestore
from services.firebase_service import get_college_dashboard, get_student_dashboard
from services.ai_service import get_recommendations
from datetime import datetime, timedelta
from collections import defaultdict
import asyncio

router = APIRouter()
db = firestore.client()


# ── Existing dashboard endpoints ──────────────────────────────────────────────

@router.get("/college/{college_id}")
async def college_dash(college_id: str):
    """College dashboard: profile, CO2 chart data, action breakdown, AI recommendations."""
    data = await asyncio.to_thread(get_college_dashboard, college_id)
    try:
        data["recommendations"] = await asyncio.to_thread(get_recommendations, data)
    except Exception as e:
        print(f"Recommendations failed: {e}")
        data["recommendations"] = []
    return data


@router.get("/student/{user_id}")
async def student_dash(user_id: str):
    """Student profile + submission history."""
    return await asyncio.to_thread(get_student_dashboard, user_id)


# ── Category mapping ─────────────────────────────────────────────────────────
# Maps actionType values to the 3 main sustainability categories shown in the app

CATEGORY_MAP = {
    "recycling":          "cutsWaste",
    "composting":         "cutsWaste",
    "cutsWaste":          "cutsWaste",
    "eWaste":             "cutsWaste",
    "water":              "optimizesResources",
    "energy":             "optimizesResources",
    "solar":              "optimizesResources",
    "optimizesResources": "optimizesResources",
    "transport":          "lowersEmissions",
    "lowersEmissions":    "lowersEmissions",
}

CATEGORY_META = {
    "cutsWaste": {
        "title": "Cut Waste",
        "icon": "♻️",
        "message": "No waste-reduction activities logged yet — try recycling, composting, or e-waste disposal.",
        "suggestions": [
            "Started composting at home",
            "Reduced single-use plastic usage",
            "Donated old electronics for recycling",
            "Organized a waste collection drive",
        ],
    },
    "optimizesResources": {
        "title": "Optimize Resources",
        "icon": "💧",
        "message": "No resource-optimization activities logged yet — try saving water, energy, or installing solar.",
        "suggestions": [
            "Installed water-saving fixtures",
            "Fixed a leaking tap",
            "Switched to LED lighting",
            "Used natural light during day",
        ],
    },
    "lowersEmissions": {
        "title": "Lower Emissions",
        "icon": "🌱",
        "message": "No emission-lowering activities logged yet — try cycling, public transport, or planting trees.",
        "suggestions": [
            "Cycled to work or college",
            "Used public transport",
            "Planted a tree",
            "Carpooled with friends",
        ],
    },
}


# ── Helper: build impact report from a list of submission dicts ───────────────

def _build_impact_report(submissions: list, entity_name: str = "You") -> dict:
    """
    Aggregates a list of submission dicts into weekly/monthly/yearly buckets,
    computes blind spots, and generates a narrative text report.
    Works for both individual users and colleges.
    """
    now = datetime.utcnow()

    # ── Aggregate totals ─────────────────────────────────────────────────────
    summary = {
        "totalCo2Kg": 0,
        "totalEnergyKwh": 0,
        "totalWaterL": 0,
        "totalEWasteKg": 0,
        "totalStardust": 0,
        "totalCostSavingRupees": 0,
        "totalActions": len(submissions),
    }
    action_counts = defaultdict(int)
    category_counts = {"cutsWaste": 0, "optimizesResources": 0, "lowersEmissions": 0}

    # Buckets keyed by period label
    weekly_buckets = defaultdict(lambda: _empty_bucket())
    monthly_buckets = defaultdict(lambda: _empty_bucket())
    yearly_buckets = defaultdict(lambda: _empty_bucket())

    for s in submissions:
        co2 = _num(s.get("co2ReducedKg", 0))
        energy = _num(s.get("energySavedKwh", 0))
        water = _num(s.get("waterSavedLiters", 0))
        ewaste = _num(s.get("eWasteKg", 0))
        stardust = _num(s.get("stardustAwarded", 0))
        cost = _num(s.get("estimatedCostSavingRupees", 0))

        summary["totalCo2Kg"] += co2
        summary["totalEnergyKwh"] += energy
        summary["totalWaterL"] += water
        summary["totalEWasteKg"] += ewaste
        summary["totalStardust"] += stardust
        summary["totalCostSavingRupees"] += cost

        action_type = s.get("actionType", "other")
        action_counts[action_type] += 1

        parent_cat = CATEGORY_MAP.get(action_type)
        if parent_cat:
            category_counts[parent_cat] += 1

        # Parse date for bucketing
        created = s.get("createdAt", "")
        try:
            dt = datetime.fromisoformat(created.replace("Z", "+00:00").split("+")[0])
        except (ValueError, AttributeError):
            dt = now

        # Weekly bucket (ISO week)
        iso_year, iso_week, _ = dt.isocalendar()
        week_start = dt - timedelta(days=dt.weekday())
        week_label = f"{week_start.strftime('%b %d')} – {(week_start + timedelta(days=6)).strftime('%b %d')}"
        week_key = f"{iso_year}-W{iso_week:02d}"
        _add_to_bucket(weekly_buckets[week_key], co2, energy, water, ewaste, stardust)
        weekly_buckets[week_key]["label"] = week_label

        # Monthly bucket
        month_key = dt.strftime("%Y-%m")
        month_label = dt.strftime("%B %Y")
        _add_to_bucket(monthly_buckets[month_key], co2, energy, water, ewaste, stardust)
        monthly_buckets[month_key]["label"] = month_label

        # Yearly bucket
        year_key = str(dt.year)
        _add_to_bucket(yearly_buckets[year_key], co2, energy, water, ewaste, stardust)
        yearly_buckets[year_key]["label"] = year_key

    # Sort buckets by key (chronological)
    weekly = [{"period": k, **v} for k, v in sorted(weekly_buckets.items())]
    monthly = [{"period": k, **v} for k, v in sorted(monthly_buckets.items())]
    yearly = [{"period": k, **v} for k, v in sorted(yearly_buckets.items())]

    # ── Blind spots ──────────────────────────────────────────────────────────
    blind_spots = []
    for cat_id, count in category_counts.items():
        if count == 0:
            meta = CATEGORY_META[cat_id]
            blind_spots.append({
                "category": cat_id,
                "title": meta["title"],
                "icon": meta["icon"],
                "message": meta["message"],
                "suggestions": meta["suggestions"],
                "actionCount": 0,
            })

    # ── Narrative report ─────────────────────────────────────────────────────
    narrative = _generate_narrative(
        entity_name, summary, action_counts, category_counts, blind_spots, weekly
    )

    # Round floats for clean JSON
    summary["totalCo2Kg"] = round(summary["totalCo2Kg"], 2)
    summary["totalEnergyKwh"] = round(summary["totalEnergyKwh"], 2)
    summary["totalWaterL"] = round(summary["totalWaterL"], 2)
    summary["totalEWasteKg"] = round(summary["totalEWasteKg"], 2)
    summary["totalCostSavingRupees"] = round(summary["totalCostSavingRupees"], 2)

    return {
        "summary": summary,
        "weekly": weekly,
        "monthly": monthly,
        "yearly": yearly,
        "actionBreakdown": dict(action_counts),
        "categoryBreakdown": category_counts,
        "blindSpots": blind_spots,
        "narrativeReport": narrative,
    }


def _empty_bucket() -> dict:
    return {"co2Kg": 0, "energyKwh": 0, "waterL": 0, "eWasteKg": 0, "stardust": 0, "actions": 0, "label": ""}


def _add_to_bucket(bucket, co2, energy, water, ewaste, stardust):
    bucket["co2Kg"] += co2
    bucket["energyKwh"] += energy
    bucket["waterL"] += water
    bucket["eWasteKg"] += ewaste
    bucket["stardust"] += stardust
    bucket["actions"] += 1


def _num(val) -> float:
    try:
        return float(val)
    except (TypeError, ValueError):
        return 0.0


def _generate_narrative(name, summary, action_counts, category_counts, blind_spots, weekly) -> str:
    """Build a human-readable narrative from aggregated data."""
    parts = []
    parts.append(f"## 🌍 Sustainability Impact Report")
    parts.append("")

    total = summary["totalActions"]
    if total == 0:
        parts.append(f"*{name} haven't logged any eco-actions yet. Start making an impact today!*")
        return "\n".join(parts)

    # Overall summary
    parts.append(f"### Overall Impact")
    parts.append(f"Across **{total} recorded actions**, here's what's been achieved:")
    parts.append("")

    highlights = []
    if summary["totalCo2Kg"] > 0:
        trees = round(summary["totalCo2Kg"] / 22, 1)  # ~22 kg CO₂ per tree per year
        highlights.append(f"🌿 **{summary['totalCo2Kg']:.1f} kg of CO₂** reduced — equivalent to planting **{trees} trees**")
    if summary["totalEnergyKwh"] > 0:
        homes = round(summary["totalEnergyKwh"] / 900, 1)  # avg Indian home ~900 kWh/yr
        highlights.append(f"⚡ **{summary['totalEnergyKwh']:.1f} kWh** of energy saved — enough to power **{homes} homes** for a year")
    if summary["totalWaterL"] > 0:
        bottles = int(summary["totalWaterL"] / 0.5)
        highlights.append(f"💧 **{summary['totalWaterL']:.0f} liters** of water saved — that's **{bottles:,} bottles**")
    if summary["totalEWasteKg"] > 0:
        highlights.append(f"🔌 **{summary['totalEWasteKg']:.1f} kg** of e-waste properly handled")
    if summary["totalCostSavingRupees"] > 0:
        highlights.append(f"💰 Estimated **₹{summary['totalCostSavingRupees']:,.0f}** saved")
    if summary["totalStardust"] > 0:
        highlights.append(f"✨ **{int(summary['totalStardust'])} Stardust** earned")

    parts.extend(highlights)
    parts.append("")

    # Most active category
    if action_counts:
        top_action = max(action_counts, key=action_counts.get)
        emoji_map = {
            "solar": "☀️", "composting": "🌿", "recycling": "♻️", "eWaste": "🔌",
            "water": "💧", "energy": "💡", "transport": "🚲", "cutsWaste": "🗑️",
            "optimizesResources": "⚡", "lowersEmissions": "🌱",
        }
        emoji = emoji_map.get(top_action, "🌍")
        parts.append(f"### Top Focus Area")
        parts.append(f"{emoji} Most frequent action: **{top_action}** ({action_counts[top_action]} times)")
        parts.append("")

    # Recent week highlight
    if weekly:
        last_week = weekly[-1]
        if last_week["actions"] > 0:
            parts.append(f"### This Week ({last_week['label']})")
            parts.append(f"Logged **{last_week['actions']} actions** this week")
            if last_week["co2Kg"] > 0:
                parts.append(f"- Saved **{last_week['co2Kg']:.1f} kg CO₂**")
            if last_week["energyKwh"] > 0:
                parts.append(f"- Saved **{last_week['energyKwh']:.1f} kWh** energy")
            if last_week["waterL"] > 0:
                parts.append(f"- Saved **{last_week['waterL']:.0f}L** water")
            parts.append("")

    # Blind spots
    if blind_spots:
        parts.append(f"### ⚠️ Blind Spots")
        parts.append("These sustainability categories haven't been explored yet:")
        parts.append("")
        for bs in blind_spots:
            parts.append(f"- **{bs['icon']} {bs['title']}** — {bs['message']}")
        parts.append("")
        parts.append("*Try exploring these areas to build a well-rounded sustainability profile!*")

    return "\n".join(parts)


# ── Impact report endpoints ───────────────────────────────────────────────────

def _fetch_user_impact_report(user_id: str) -> dict:
    """Blocking Firestore read — runs in thread pool."""
    snaps = db.collection("submissions").where("userId", "==", user_id).stream()
    submissions = [s.to_dict() for s in snaps]

    # Get user name for the narrative
    user_doc = db.collection("users").document(user_id).get()
    user_name = "You"
    if user_doc.exists:
        user_data = user_doc.to_dict() or {}
        user_name = user_data.get("name", "You").split(" ")[0]

    return _build_impact_report(submissions, entity_name=user_name)


def _fetch_college_impact_report(college_id: str) -> dict:
    """Blocking Firestore read — runs in thread pool."""
    snaps = db.collection("submissions").where("collegeId", "==", college_id).stream()
    submissions = [s.to_dict() for s in snaps]

    # Get college name for the narrative
    college_doc = db.collection("colleges").document(college_id).get()
    college_name = "Your institution"
    if college_doc.exists:
        college_data = college_doc.to_dict() or {}
        college_name = college_data.get("name", "Your institution")

    return _build_impact_report(submissions, entity_name=college_name)


@router.get("/impact-report/college/{college_id}")
async def college_impact_report(college_id: str):
    """
    College/org impact report — aggregates all submissions from students
    belonging to this college into weekly/monthly/yearly data, charts,
    blind spots, and a narrative text report.
    """
    return await asyncio.to_thread(_fetch_college_impact_report, college_id)


@router.get("/impact-report/{user_id}")
async def user_impact_report(user_id: str):
    """
    Individual/student impact report — aggregates user's own submissions
    into weekly/monthly/yearly data, charts, blind spots, and a narrative
    text report.
    """
    return await asyncio.to_thread(_fetch_user_impact_report, user_id)