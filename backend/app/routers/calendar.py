from fastapi import APIRouter, Depends

from app.routers.auth import get_current_user_id
from app.database import get_supabase
from app.services.calendar_service import fetch_events_for_entity, get_oauth_url_for_entity

router = APIRouter(prefix="/calendar", tags=["calendar"])


@router.get("/connect")
async def connect_calendar(user_id: str = Depends(get_current_user_id)) -> dict:
    db = get_supabase()
    entity_id = f"user_{user_id}"
    result = get_oauth_url_for_entity(entity_id)
    db.table("profiles").update({"composio_entity_id": entity_id}).eq("id", user_id).execute()
    return result


@router.get("/status")
async def calendar_status(user_id: str = Depends(get_current_user_id)) -> dict:
    db = get_supabase()
    res = db.table("profiles").select("calendar_connected").eq("id", user_id).maybe_single().execute()
    connected = (res.data or {}).get("calendar_connected", False)
    return {"connected": connected}


@router.get("/callback")
async def calendar_callback(user_id: str = Depends(get_current_user_id)) -> dict:
    db = get_supabase()
    db.table("profiles").update({"calendar_connected": True}).eq("id", user_id).execute()
    return {"message": "Google Calendar connected successfully"}


@router.get("/events")
async def get_events(
    hours: int = 12,
    user_id: str = Depends(get_current_user_id),
) -> list[dict]:
    db = get_supabase()
    res = (
        db.table("profiles")
        .select("composio_entity_id,calendar_connected")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )
    data = res.data or {}
    if not data.get("calendar_connected"):
        return []
    entity_id = data.get("composio_entity_id")
    if not entity_id:
        return []
    return fetch_events_for_entity(entity_id, hours)
