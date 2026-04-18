import datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.routers.auth import get_current_user_id
from app.database import get_supabase
from app.services.ai_service import generate_chat_response
from app.services.memory_service import add_memory, search_memories
from app.services.calendar_service import fetch_events_for_entity
from app.services.restaurant_service import search_nearby_restaurants

router = APIRouter(prefix="/chat", tags=["chat"])


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    response: str


@router.post("/message", response_model=ChatResponse)
async def send_message(
    request: ChatRequest,
    user_id: str = Depends(get_current_user_id),
) -> ChatResponse:
    db = get_supabase()

    profile_res = db.table("profiles").select("*").eq("id", user_id).maybe_single().execute()
    profile = profile_res.data or {}

    loc_res = db.table("user_locations").select("*").eq("user_id", user_id).maybe_single().execute()
    location = loc_res.data

    history_res = (
        db.table("chat_messages")
        .select("role,content")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .limit(20)
        .execute()
    )
    history = list(reversed(history_res.data or []))

    scores_res = (
        db.table("meal_scores")
        .select("meal_name,score,notes,eaten_at")
        .eq("user_id", user_id)
        .order("eaten_at", desc=True)
        .limit(5)
        .execute()
    )
    recent_scores = scores_res.data or []

    memories = await search_memories(user_id, request.message)

    calendar_events: list[dict] = []
    entity_id = profile.get("composio_entity_id")
    if profile.get("calendar_connected") and entity_id:
        calendar_events = fetch_events_for_entity(entity_id, hours=12)

    nearby_restaurants: list[dict] = []
    _food_keywords = {"eat", "food", "restaurant", "meal", "lunch", "dinner", "breakfast", "order", "hungry", "near", "local", "grab"}
    if location and any(kw in request.message.lower() for kw in _food_keywords):
        city = (location or {}).get("city", "")
        if city:
            nearby_restaurants = await search_nearby_restaurants(city)

    response_text = await generate_chat_response(
        message=request.message,
        history=history,
        profile=profile,
        location=location,
        calendar_events=calendar_events,
        memories=memories,
        recent_scores=recent_scores,
        nearby_restaurants=nearby_restaurants,
    )

    now = datetime.datetime.utcnow().isoformat()
    db.table("chat_messages").insert([
        {"user_id": user_id, "role": "user", "content": request.message, "created_at": now},
        {"user_id": user_id, "role": "assistant", "content": response_text, "created_at": now},
    ]).execute()

    await add_memory(
        user_id=user_id,
        content=f"User: {request.message}\nAssistant: {response_text}",
        metadata={"type": "conversation", "date": now},
    )

    return ChatResponse(response=response_text)


@router.get("/history")
async def get_history(
    limit: int = 50,
    user_id: str = Depends(get_current_user_id),
) -> list[dict]:
    db = get_supabase()
    result = (
        db.table("chat_messages")
        .select("id,role,content,created_at")
        .eq("user_id", user_id)
        .order("created_at", desc=False)
        .limit(limit)
        .execute()
    )
    return result.data or []
