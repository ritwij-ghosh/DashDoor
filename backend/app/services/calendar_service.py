import asyncio
from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.user import User


def _get_oauth_url_sync(entity_id: str) -> dict:
    from composio import ComposioToolSet, App

    toolset = ComposioToolSet(api_key=settings.COMPOSIO_API_KEY)
    entity = toolset.get_entity(entity_id)
    connection_request = entity.initiate_connection(app=App.GOOGLECALENDAR)
    return {
        "oauth_url": connection_request.redirectUrl,
        "entity_id": entity_id,
    }


def _fetch_events_sync(entity_id: str, hours: int) -> list[dict]:
    from composio import ComposioToolSet, Action

    now = datetime.now(timezone.utc)
    window_end = now + timedelta(hours=hours)

    toolset = ComposioToolSet(api_key=settings.COMPOSIO_API_KEY)
    response = toolset.execute_action(
        action=Action.GOOGLECALENDAR_FIND_EVENT,
        params={
            "calendarId": "primary",
            "timeMin": now.isoformat(),
            "timeMax": window_end.isoformat(),
            "maxResults": 20,
            "singleEvents": True,
            "orderBy": "startTime",
        },
        entity_id=entity_id,
    )

    events: list[dict] = []
    data = response if isinstance(response, dict) else {}

    # Composio returns {"successful": True, "data": {"items": [...]}}
    items = []
    if isinstance(data, dict):
        inner = data.get("data") or data.get("response_data") or data
        if isinstance(inner, dict):
            items = inner.get("items") or inner.get("events") or []
        elif isinstance(inner, list):
            items = inner

    for item in items:
        if not isinstance(item, dict):
            continue
        start_raw = item.get("start", {})
        end_raw = item.get("end", {})
        events.append(
            {
                "title": item.get("summary", "Untitled"),
                "start_time": start_raw.get("dateTime") or start_raw.get("date", ""),
                "end_time": end_raw.get("dateTime") or end_raw.get("date", ""),
                "location": item.get("location"),
                "description": item.get("description"),
            }
        )
    return events


async def get_calendar_oauth_url(user: User, db: AsyncSession) -> dict:
    entity_id = str(user.id)
    result = await asyncio.to_thread(_get_oauth_url_sync, entity_id)

    # Persist entity_id and mark as connecting
    from sqlalchemy import update
    from app.database import AsyncSessionLocal

    async with AsyncSessionLocal() as session:
        await session.execute(
            update(User)
            .where(User.id == user.id)
            .values(composio_entity_id=entity_id)
        )
        await session.commit()

    return result


async def get_upcoming_events(user: User, hours: int = 12) -> list[dict]:
    if not user.calendar_connected and not user.composio_entity_id:
        return []
    entity_id = user.composio_entity_id or str(user.id)
    try:
        return await asyncio.to_thread(_fetch_events_sync, entity_id, hours)
    except Exception:
        return []


async def mark_calendar_connected(user_id: str) -> None:
    """Called after the user completes OAuth. Marks calendar as connected."""
    from sqlalchemy import update
    from app.database import AsyncSessionLocal

    async with AsyncSessionLocal() as session:
        await session.execute(
            update(User)
            .where(User.id == user_id)
            .values(calendar_connected=True)
        )
        await session.commit()
