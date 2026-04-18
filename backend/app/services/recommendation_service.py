import uuid
from datetime import datetime, timedelta

from supabase import Client

from app.services.ai_service import generate_meal_plan
from app.services.calendar_service import fetch_events_for_entity
from app.services.restaurant_service import search_nearby_restaurants


async def generate_recommendations_for_user(
    user_id: str,
    db: Client,
    location_override: str | None = None,
    travel_override: str | None = None,
) -> dict:
    profile_res = db.table("profiles").select("*").eq("id", user_id).maybe_single().execute()
    profile = (profile_res.data if profile_res else None) or {}

    loc_res = db.table("user_locations").select("*").eq("user_id", user_id).maybe_single().execute()
    location_row = loc_res.data if loc_res else None

    location = location_override or (location_row.get("city") if location_row else None) or "Unknown"
    travel_context = travel_override or (location_row.get("travel_note") if location_row else None)

    events: list[dict] = []
    entity_id = profile.get("composio_entity_id")
    if profile.get("calendar_connected") and entity_id:
        events = fetch_events_for_entity(entity_id, hours=12)

    nearby_restaurants = await search_nearby_restaurants(location)

    now = datetime.utcnow()
    plan = await generate_meal_plan(
        events=events,
        location=location,
        travel_context=travel_context,
        current_time=now,
        nearby_restaurants=nearby_restaurants,
    )

    rec_id = str(uuid.uuid4())
    row = {
        "id": rec_id,
        "user_id": user_id,
        "generated_at": now.isoformat(),
        "location": location,
        "travel_context": travel_context,
        "calendar_summary": events,
        "recommendations_json": plan,
        "window_start": now.isoformat(),
        "window_end": (now + timedelta(hours=12)).isoformat(),
    }
    db.table("recommendations").insert(row).execute()
    return row
