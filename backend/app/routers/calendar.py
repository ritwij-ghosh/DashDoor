"""Google Calendar router.

During demo/dev we use a single pre-linked Composio entity
(`DEMO_ENTITY_ID`), so these routes do not require Supabase auth. The
Flutter app can poll `/calendar/status` and pull `/calendar/events`
without a session token.
"""
from fastapi import APIRouter

from app.services.calendar_service import (
    entity_id_for,
    fetch_events_for_entity,
    get_oauth_url_for_entity,
    is_entity_connected,
)

router = APIRouter(prefix="/calendar", tags=["calendar"])


@router.get("/connect")
async def connect_calendar() -> dict:
    return get_oauth_url_for_entity(entity_id_for())


@router.get("/status")
async def calendar_status() -> dict:
    return {"connected": is_entity_connected(entity_id_for())}


@router.get("/callback")
async def calendar_callback() -> dict:
    # Composio manages the OAuth callback. This is kept for backwards
    # compatibility but the real source of truth is `is_entity_connected`.
    return {
        "message": "Google Calendar connected successfully",
        "connected": is_entity_connected(entity_id_for()),
    }


@router.get("/events")
async def get_events(hours: int = 12) -> list[dict]:
    entity_id = entity_id_for()
    if not is_entity_connected(entity_id):
        return []
    return fetch_events_for_entity(entity_id, hours)
