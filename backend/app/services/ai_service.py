import json
from datetime import datetime

import anthropic

from app.config import settings

SYSTEM_PROMPT = """You are Healthy Autopilot, a proactive nutrition AI that plans meals around a user's schedule.

Your job: analyze the user's calendar events, current location, and travel context for the next 8-12 hours, then recommend 3-5 specific, practical meals or snacks. You prevent decision fatigue by telling the user exactly what to eat and when, before they get hungry.

Rules:
- Be specific about timing (e.g. "Eat by 12:30 PM before your 1 PM block")
- Consider gaps between events — if back-to-back, suggest grab-and-go or delivery
- Factor in travel (airports, long drives) with portable options
- Keep suggestions realistic given the location
- Always return valid JSON matching the schema exactly

Output schema (JSON only, no markdown):
{
  "window_analyzed": "string describing the time window, e.g. '10:00 AM – 10:00 PM'",
  "recommendations": [
    {
      "name": "meal or snack name",
      "description": "2-3 sentence description with specifics",
      "when_to_eat": "exact time or relative timing, e.g. '12:15 PM' or 'Before your 1 PM meeting'",
      "why": "one sentence explaining why this fits their schedule",
      "estimated_calories": 450,
      "suggested_order_method": "DoorDash / UberEats / Grab ahead / Cook / Convenience store",
      "tags": ["high-protein", "grab-and-go"]
    }
  ],
  "general_advice": "1-2 sentence summary of the overall nutrition strategy for the day"
}"""


async def generate_meal_plan(
    events: list[dict],
    location: str,
    travel_context: str | None,
    current_time: datetime,
) -> dict:
    client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)

    # Build the user message
    time_str = current_time.strftime("%A, %B %d %Y at %I:%M %p %Z")

    events_block = ""
    if events:
        lines = []
        for e in events:
            line = f"- {e.get('title', 'Event')}: {e.get('start_time', '')} → {e.get('end_time', '')}"
            if e.get("location"):
                line += f" @ {e['location']}"
            lines.append(line)
        events_block = "Calendar events for next 12 hours:\n" + "\n".join(lines)
    else:
        events_block = "No calendar events found for the next 12 hours."

    travel_block = f"Travel context: {travel_context}" if travel_context else ""

    user_message = f"""Current time: {time_str}
Current location: {location}
{travel_block}

{events_block}

Generate meal and snack recommendations for the next 8-12 hours. Return only valid JSON."""

    response = await client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1500,
        system=[
            {
                "type": "text",
                "text": SYSTEM_PROMPT,
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[{"role": "user", "content": user_message}],
    )

    raw = response.content[0].text.strip()

    # Strip markdown code fences if present
    if raw.startswith("```"):
        raw = raw.split("```", 2)[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.rsplit("```", 1)[0].strip()

    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        # Return a safe fallback so the endpoint never 500s
        return {
            "window_analyzed": "Next 8-12 hours",
            "recommendations": [],
            "general_advice": raw[:500],
        }
