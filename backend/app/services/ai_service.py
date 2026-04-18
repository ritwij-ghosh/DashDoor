import json
from datetime import datetime
from typing import Optional

import anthropic

from app.config import settings

client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)

_CHAT_SYSTEM = """You are Healthy Autopilot — a proactive AI nutrition assistant that plans meals around the user's calendar, location, and life before they get hungry.

Core job:
- Analyze their upcoming schedule and proactively suggest what to eat and when
- Be specific: "Order by 11:30 AM before your 12 PM block" not vague advice
- Reference actual calendar events by name when giving timing advice
- Consider meal gaps, energy needs for the type of work, and travel constraints
- Use their dietary preferences and past meal scores to improve suggestions
- Keep responses concise and warm (3-8 sentences unless asked for more)

When suggesting meals, use this inline format:
🍽 [Meal] — [Source] | ⏰ [Time] | 💡 [Why]"""

_PLAN_SYSTEM = """You are Healthy Autopilot. Generate proactive meal recommendations for the next 8-12 hours based on the user's schedule. Return valid JSON only — no markdown fences."""


async def generate_chat_response(
    message: str,
    history: list[dict],
    profile: dict,
    location: Optional[dict],
    calendar_events: list[dict],
    memories: list[str],
    recent_scores: list[dict],
) -> str:
    ctx: list[str] = []

    if profile.get("name"):
        ctx.append(f"User: {profile['name']}")
    if profile.get("dietary_preferences"):
        prefs = profile["dietary_preferences"]
        if isinstance(prefs, list) and prefs:
            ctx.append(f"Diet: {', '.join(prefs)}")
    if profile.get("health_goals"):
        ctx.append(f"Goals: {profile['health_goals']}")

    if location:
        loc = location.get("city", "")
        if location.get("travel_note"):
            loc += f" — {location['travel_note']}"
        ctx.append(f"Location: {loc}")

    ctx.append(f"Current time: {datetime.now().strftime('%A %b %d, %I:%M %p')}")

    if calendar_events:
        ctx.append("Calendar (next 12h):")
        for e in calendar_events:
            line = f"  • {e.get('title', 'Event')} {e.get('start_time', '')}–{e.get('end_time', '')}"
            if e.get("location"):
                line += f" @ {e['location']}"
            ctx.append(line)
    else:
        ctx.append("No calendar events connected.")

    if recent_scores:
        ctx.append("Recent meal ratings:")
        for s in recent_scores:
            note = f": {s['notes']}" if s.get("notes") else ""
            ctx.append(f"  • {s['meal_name']} — {s['score']}/5{note}")

    if memories:
        ctx.append("Memory:")
        for m in memories[:3]:
            ctx.append(f"  • {m}")

    msgs = [{"role": h["role"], "content": h["content"]} for h in history[-10:]]
    msgs.append({"role": "user", "content": message})

    resp = await client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        system=[
            {"type": "text", "text": _CHAT_SYSTEM, "cache_control": {"type": "ephemeral"}},
            {"type": "text", "text": "[CONTEXT]\n" + "\n".join(ctx)},
        ],
        messages=msgs,
    )
    return resp.content[0].text


async def generate_meal_plan(
    events: list[dict],
    location: str,
    travel_context: Optional[str],
    current_time: datetime,
) -> dict:
    events_block = ""
    if events:
        lines = []
        for e in events:
            line = f"- {e.get('title', 'Event')}: {e.get('start_time', '')} → {e.get('end_time', '')}"
            if e.get("location"):
                line += f" @ {e['location']}"
            lines.append(line)
        events_block = "Calendar events:\n" + "\n".join(lines)
    else:
        events_block = "No calendar events."

    prompt = f"""Current time: {current_time.strftime('%A, %B %d %Y at %I:%M %p')}
Location: {location or 'Unknown'}
{f'Travel: {travel_context}' if travel_context else ''}

{events_block}

Return JSON matching this schema exactly:
{{
  "window_analyzed": "e.g. 8am–8pm",
  "recommendations": [
    {{
      "name": "Meal name",
      "description": "2-3 sentences",
      "when_to_eat": "12:30 PM",
      "why": "One sentence tied to their schedule",
      "calories": 600,
      "order_method": "DoorDash / walk-in / prep",
      "tags": ["high-protein", "quick"]
    }}
  ],
  "general_advice": "One sentence overall strategy"
}}

Include 3-5 recommendations."""

    resp = await client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1500,
        system=[{"type": "text", "text": _PLAN_SYSTEM, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": prompt}],
    )
    raw = resp.content[0].text.strip()
    if raw.startswith("```"):
        raw = raw.split("```", 2)[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.rsplit("```", 1)[0].strip()
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"window_analyzed": "Next 8-12 hours", "recommendations": [], "general_advice": raw[:300]}
