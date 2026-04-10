"""
dashboard.py — Impact Report, Charts, and Blind Spot Analysis

All three features live here:
  1. Impact Tracking Report   → narrativeReport (Markdown text, AI insights per activity)
  2. Graphical Representation → chartSeries (parallel arrays per metric, ready for fl_chart)
  3. Inaction Highlighting    → blindSpots (category scoring, suggestions, coverage %)

Endpoints:
  GET /dashboard/impact-report/{user_id}
  GET /dashboard/impact-report/college/{college_id}
  GET /dashboard/college/{college_id}   (existing college dashboard)
  GET /dashboard/student/{user_id}      (existing student dashboard)
"""

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


# ── Category mapping ──────────────────────────────────────────────────────────
# Maps fine-grained actionType → one of the 3 main sustainability pillars

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

EMOJI_MAP = {
    "solar": "☀️", "composting": "🌿", "recycling": "♻️", "eWaste": "🔌",
    "water": "💧", "energy": "💡", "transport": "🚲", "cutsWaste": "🗑️",
    "optimizesResources": "⚡", "lowersEmissions": "🌱", "other": "🌍",
}

CATEGORY_META = {
    "cutsWaste": {
        "title": "Cut Waste",
        "icon": "♻️",
        "pillar": "Reduces Waste",
        "message": "No waste-reduction activities logged yet — try recycling, composting, or e-waste disposal.",
        "suggestions": [
            "Start composting food scraps at home or campus",
            "Reduce single-use plastic — carry a reusable bag/bottle",
            "Donate or recycle old electronics instead of discarding them",
            "Organize a waste collection or cleanup drive",
        ],
    },
    "optimizesResources": {
        "title": "Optimize Resources",
        "icon": "💧",
        "pillar": "Optimizes Resource Usage",
        "message": "No resource-optimization activities logged yet — try saving water, energy, or installing solar.",
        "suggestions": [
            "Install water-saving fixtures or fix leaking taps",
            "Switch to LED lighting across campus or home",
            "Use natural light during daytime hours",
            "Install solar panels or renewable energy sources",
        ],
    },
    "lowersEmissions": {
        "title": "Lower Emissions",
        "icon": "🌱",
        "pillar": "Lowers Emissions",
        "message": "No emission-lowering activities logged yet — try cycling, public transport, or planting trees.",
        "suggestions": [
            "Cycle or walk to campus instead of using private vehicles",
            "Use public transport or carpool with others",
            "Plant trees or participate in a plantation drive",
            "Reduce air-conditioner usage and switch to fans",
        ],
    },
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _num(val) -> float:
    try:
        return float(val)
    except (TypeError, ValueError):
        return 0.0


def _empty_bucket() -> dict:
    return {
        "co2Kg": 0.0, "energyKwh": 0.0, "waterL": 0.0,
        "eWasteKg": 0.0, "stardust": 0.0, "actions": 0, "label": "",
    }


def _add_to_bucket(bucket, co2, energy, water, ewaste, stardust):
    bucket["co2Kg"]     += co2
    bucket["energyKwh"] += energy
    bucket["waterL"]    += water
    bucket["eWasteKg"]  += ewaste
    bucket["stardust"]  += stardust
    bucket["actions"]   += 1


def _parse_dt(created: str, fallback: datetime) -> datetime:
    try:
        return datetime.fromisoformat(created.replace("Z", "+00:00").split("+")[0])
    except (ValueError, AttributeError):
        return fallback


# ── Core builder ──────────────────────────────────────────────────────────────

def _build_impact_report(submissions: list, entity_name: str = "You") -> dict:
    """
    Feature 1 — Impact Tracking Report:
      Aggregates all submission data into weekly/monthly/yearly buckets.
      Includes AI-generated impact insights per activity in the narrative.

    Feature 2 — Graphical Representation:
      Returns chartSeries: parallel arrays (labels, co2, energy, water)
      for weekly / monthly / yearly views — directly usable by fl_chart.

    Feature 3 — Inaction Highlighting (Blind Spots):
      Scores each of the 3 pillars as a % of total actions.
      Flags categories with 0 actions as blind spots, low-count (<15%) as warnings.
    """
    now = datetime.utcnow()

    # ── Aggregate totals ─────────────────────────────────────────────────────
    summary = {
        "totalCo2Kg": 0.0,
        "totalEnergyKwh": 0.0,
        "totalWaterL": 0.0,
        "totalEWasteKg": 0.0,
        "totalStardust": 0.0,
        "totalCostSavingRupees": 0.0,
        "totalActions": len(submissions),
    }
    action_counts = defaultdict(int)
    category_counts = {"cutsWaste": 0, "optimizesResources": 0, "lowersEmissions": 0}

    # Time-series buckets
    weekly_buckets  = defaultdict(lambda: _empty_bucket())
    monthly_buckets = defaultdict(lambda: _empty_bucket())
    yearly_buckets  = defaultdict(lambda: _empty_bucket())

    # Feature 1 extra: collect per-activity insight sentences (from AI)
    activity_insights = []   # [{date, emoji, actionType, impactSummary, realWorldEquivalent, co2Kg}]

    for s in submissions:
        co2      = _num(s.get("co2ReducedKg", 0))
        energy   = _num(s.get("energySavedKwh", 0))
        water    = _num(s.get("waterSavedLiters", 0))
        ewaste   = _num(s.get("eWasteKg", 0))
        stardust = _num(s.get("stardustAwarded", 0))
        cost     = _num(s.get("estimatedCostSavingRupees", 0))

        summary["totalCo2Kg"]             += co2
        summary["totalEnergyKwh"]         += energy
        summary["totalWaterL"]            += water
        summary["totalEWasteKg"]          += ewaste
        summary["totalStardust"]          += stardust
        summary["totalCostSavingRupees"]  += cost

        action_type = s.get("actionType", "other")
        action_counts[action_type] += 1
        parent_cat = CATEGORY_MAP.get(action_type)
        if parent_cat:
            category_counts[parent_cat] += 1

        # Collect insight sentence
        impact_summary = s.get("impactSummary", "").strip()
        real_world     = s.get("realWorldEquivalent", "").strip()
        created_str    = s.get("createdAt", "")
        date_label     = created_str[:10] if created_str else "Unknown date"

        if impact_summary:
            activity_insights.append({
                "date":               date_label,
                "actionType":         action_type,
                "emoji":              EMOJI_MAP.get(action_type, "🌍"),
                "impactSummary":      impact_summary,
                "realWorldEquivalent": real_world or None,
                "co2Kg":              round(co2, 2),
                "energyKwh":          round(energy, 2),
                "stardust":           int(stardust),
            })

        # Time buckets
        dt = _parse_dt(created_str, now)

        iso_year, iso_week, _ = dt.isocalendar()
        week_start = dt - timedelta(days=dt.weekday())
        week_label = f"{week_start.strftime('%b %d')} – {(week_start + timedelta(days=6)).strftime('%b %d')}"
        week_key   = f"{iso_year}-W{iso_week:02d}"
        _add_to_bucket(weekly_buckets[week_key], co2, energy, water, ewaste, stardust)
        weekly_buckets[week_key]["label"] = week_label

        month_key   = dt.strftime("%Y-%m")
        month_label = dt.strftime("%B %Y")
        _add_to_bucket(monthly_buckets[month_key], co2, energy, water, ewaste, stardust)
        monthly_buckets[month_key]["label"] = month_label

        year_key = str(dt.year)
        _add_to_bucket(yearly_buckets[year_key], co2, energy, water, ewaste, stardust)
        yearly_buckets[year_key]["label"] = year_key

    # Sort buckets chronologically
    weekly  = [{"period": k, **v} for k, v in sorted(weekly_buckets.items())]
    monthly = [{"period": k, **v} for k, v in sorted(monthly_buckets.items())]
    yearly  = [{"period": k, **v} for k, v in sorted(yearly_buckets.items())]

    # Sort activity insights newest-first; keep top 20 for narrative
    activity_insights.sort(key=lambda x: x["date"], reverse=True)

    # ── Feature 2: Chart Series ───────────────────────────────────────────────
    # Pre-built parallel arrays for fl_chart BarChart / LineChart.
    # Flutter reads: chartSeries["weekly"]["labels"][i], chartSeries["weekly"]["co2"][i]
    def _to_chart_series(buckets: list) -> dict:
        return {
            "labels":     [b["label"] or b["period"] for b in buckets],
            "co2":        [round(b["co2Kg"], 2)     for b in buckets],
            "energy":     [round(b["energyKwh"], 2) for b in buckets],
            "water":      [round(b["waterL"], 1)    for b in buckets],
            "eWaste":     [round(b["eWasteKg"], 2)  for b in buckets],
            "stardust":   [round(b["stardust"], 0)  for b in buckets],
            "actions":    [b["actions"]             for b in buckets],
        }

    chart_series = {
        "weekly":  _to_chart_series(weekly),
        "monthly": _to_chart_series(monthly),
        "yearly":  _to_chart_series(yearly),
    }

    # ── Feature 3: Blind Spots / Inaction Highlighting ────────────────────────
    total_actions = max(summary["totalActions"], 1)  # avoid division by zero
    blind_spots = []
    category_scores = {}  # coverage % per pillar

    for cat_id, count in category_counts.items():
        pct = round((count / total_actions) * 100, 1)
        category_scores[cat_id] = {"count": count, "coveragePct": pct}
        meta = CATEGORY_META[cat_id]

        if count == 0:
            severity = "blind"     # Never explored — hard red
        elif pct < 15:
            severity = "low"       # Very low engagement — amber warning
        else:
            severity = "ok"

        if severity in ("blind", "low"):
            blind_spots.append({
                "category":    cat_id,
                "pillar":      meta["pillar"],
                "title":       meta["title"],
                "icon":        meta["icon"],
                "message":     meta["message"],
                "suggestions": meta["suggestions"],
                "actionCount": count,
                "coveragePct": pct,
                "severity":    severity,   # "blind" | "low"
            })

    # ── Feature 1: Narrative Report ───────────────────────────────────────────
    narrative = _generate_narrative(
        entity_name, summary, action_counts, category_counts,
        blind_spots, weekly, activity_insights
    )

    # Round summary floats
    for key in ("totalCo2Kg", "totalEnergyKwh", "totalWaterL", "totalEWasteKg", "totalCostSavingRupees"):
        summary[key] = round(summary[key], 2)

    return {
        # Feature 1
        "summary":          summary,
        "narrativeReport":  narrative,
        "activityInsights": activity_insights[:20],  # top 20 newest AI insights

        # Feature 2
        "weekly":           weekly,
        "monthly":          monthly,
        "yearly":           yearly,
        "chartSeries":      chart_series,          # ← NEW: parallel arrays for fl_chart
        "actionBreakdown":  dict(action_counts),
        "categoryBreakdown": category_counts,

        # Feature 3
        "blindSpots":       blind_spots,
        "categoryScores":   category_scores,       # ← NEW: coverage % per pillar
    }


# ── Narrative generator ───────────────────────────────────────────────────────

def _generate_narrative(
    name: str,
    summary: dict,
    action_counts: dict,
    category_counts: dict,
    blind_spots: list,
    weekly: list,
    activity_insights: list,
) -> str:
    """
    Builds a rich Markdown narrative that:
    - Opens with aggregate impact (numbers → relatable analogies)
    - Lists individual AI-generated insight sentences (the specific "saved X by doing Y" lines)
    - Highlights the current week
    - Calls out blind spots with actionable suggestions
    """
    parts = ["## 🌍 Sustainability Impact Report", ""]

    total = summary["totalActions"]
    if total == 0:
        parts.append(f"*{name} hasn't logged any eco-actions yet. Start making an impact today!*")
        return "\n".join(parts)

    # ── Section 1: Overall aggregate ──────────────────────────────────────────
    parts += [f"### ✨ Overall Impact", f"Across **{total} recorded actions**, here's what's been achieved:", ""]

    if summary["totalCo2Kg"] > 0:
        trees = round(summary["totalCo2Kg"] / 22, 1)
        parts.append(f"🌿 **{summary['totalCo2Kg']:.1f} kg of CO₂** reduced — equivalent to planting **{trees} trees**")
    if summary["totalEnergyKwh"] > 0:
        homes = round(summary["totalEnergyKwh"] / 900, 2)
        parts.append(f"⚡ **{summary['totalEnergyKwh']:.1f} kWh** of energy saved — powers **{homes} Indian homes** for a year")
    if summary["totalWaterL"] > 0:
        bottles = int(summary["totalWaterL"] / 0.5)
        parts.append(f"💧 **{summary['totalWaterL']:.0f} liters** of water saved — that's **{bottles:,} plastic bottles**")
    if summary["totalEWasteKg"] > 0:
        parts.append(f"🔌 **{summary['totalEWasteKg']:.1f} kg** of e-waste properly diverted from landfills")
    if summary["totalCostSavingRupees"] > 0:
        parts.append(f"💰 Estimated **₹{summary['totalCostSavingRupees']:,.0f}** in cost savings")
    if summary["totalStardust"] > 0:
        parts.append(f"✨ **{int(summary['totalStardust'])} Stardust** earned")
    parts.append("")

    # ── Section 2: Top focus area ─────────────────────────────────────────────
    if action_counts:
        top_action = max(action_counts, key=action_counts.get)
        emoji = EMOJI_MAP.get(top_action, "🌍")
        parts += [
            "### 🏆 Top Focus Area",
            f"{emoji} Most frequent action: **{top_action}** ({action_counts[top_action]} times)",
            "",
        ]

    # ── Section 3: Activity-level AI insights ─────────────────────────────────
    # These are the specific sentences from the AI for each recorded activity
    useful_insights = [i for i in activity_insights if i.get("impactSummary")]
    if useful_insights:
        parts += ["### 📋 Your Activity Insights", ""]
        for insight in useful_insights[:10]:  # Show newest 10
            emoji = insight.get("emoji", "🌍")
            date  = insight.get("date", "")
            text  = insight["impactSummary"]
            rw    = insight.get("realWorldEquivalent", "")
            line  = f"- {emoji} **{date}** — {text}"
            if rw:
                line += f" *(~{rw})*"
            parts.append(line)
        parts.append("")

    # ── Section 4: This week ──────────────────────────────────────────────────
    if weekly:
        last = weekly[-1]
        if last["actions"] > 0:
            parts += [f"### 📅 This Week ({last['label']})", f"Logged **{last['actions']} actions**"]
            if last["co2Kg"] > 0:
                parts.append(f"- Saved **{round(last['co2Kg'], 1)} kg CO₂**")
            if last["energyKwh"] > 0:
                parts.append(f"- Saved **{round(last['energyKwh'], 1)} kWh** of energy")
            if last["waterL"] > 0:
                parts.append(f"- Conserved **{int(last['waterL'])} liters** of water")
            parts.append("")

    # ── Section 5: Category coverage ─────────────────────────────────────────
    parts += ["### 📊 Category Coverage", ""]
    for cat_id, meta in CATEGORY_META.items():
        count = category_counts.get(cat_id, 0)
        total_safe = max(total, 1)
        pct   = round((count / total_safe) * 100)
        bar_filled = int(pct / 10)
        bar = "█" * bar_filled + "░" * (10 - bar_filled)
        parts.append(f"{meta['icon']} **{meta['title']}** `{bar}` {pct}% ({count} actions)")
    parts.append("")

    # ── Section 6: Blind spots ────────────────────────────────────────────────
    if blind_spots:
        parts += [
            "### ⚠️ Areas Needing Attention",
            "These sustainability pillars are underrepresented in the activity log:",
            "",
        ]
        for bs in blind_spots:
            severity_label = "🔴 Not started" if bs["severity"] == "blind" else "🟡 Very low activity"
            parts.append(f"**{bs['icon']} {bs['title']}** — {severity_label} ({bs['coveragePct']}%)")
            parts.append(f"  {bs['message']}")
            parts.append("  *Suggested actions:*")
            for sug in bs["suggestions"][:2]:
                parts.append(f"  - {sug}")
            parts.append("")
        parts.append("*Building a balanced sustainability profile means engaging all three pillars!*")
    else:
        parts += [
            "### 🌟 Well-Rounded Sustainability Profile",
            "Excellent! All three sustainability pillars are being actively addressed.",
            "*Keep it up — consistency is the key to long-term impact.*",
        ]

    return "\n".join(parts)


# ── Firestore fetch helpers ───────────────────────────────────────────────────

def _fetch_user_impact_report(user_id: str) -> dict:
    """Blocking Firestore read — runs in thread pool via asyncio.to_thread."""
    snaps = db.collection("submissions").where("userId", "==", user_id).stream()
    submissions = [s.to_dict() for s in snaps]

    user_doc  = db.collection("users").document(user_id).get()
    user_name = "You"
    if user_doc.exists:
        u = user_doc.to_dict() or {}
        user_name = u.get("name", "You").split(" ")[0]

    return _build_impact_report(submissions, entity_name=user_name)


def _fetch_college_impact_report(college_id: str) -> dict:
    """Blocking Firestore read — runs in thread pool via asyncio.to_thread."""
    snaps = db.collection("submissions").where("collegeId", "==", college_id).stream()
    submissions = [s.to_dict() for s in snaps]

    col_doc      = db.collection("colleges").document(college_id).get()
    college_name = "Your institution"
    if col_doc.exists:
        c = col_doc.to_dict() or {}
        college_name = c.get("name", "Your institution")

    return _build_impact_report(submissions, entity_name=college_name)


# ── API Endpoints ─────────────────────────────────────────────────────────────
# IMPORTANT: more-specific routes MUST come before wildcard routes in FastAPI.
# /impact-report/college/{id} must be registered before /impact-report/{user_id}
# otherwise FastAPI will match the word "college" as a user_id.

@router.get("/impact-report/college/{college_id}")
async def college_impact_report(college_id: str):
    """
    College/org impact report.
    Returns all 3 features: narrativeReport, chartSeries, blindSpots.
    """
    return await asyncio.to_thread(_fetch_college_impact_report, college_id)


@router.get("/impact-report/user/{user_id}")
@router.get("/impact-report/{user_id}")
async def user_impact_report(user_id: str):
    """
    Individual user impact report.
    Returns all 3 features: narrativeReport, chartSeries, blindSpots.
    Also accessible at /impact-report/user/{user_id} as an explicit alias.
    """
    return await asyncio.to_thread(_fetch_user_impact_report, user_id)