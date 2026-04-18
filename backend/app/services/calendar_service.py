"""Google Calendar integration via Composio.

All calls go through the Composio Python SDK using the `COMPOSIO_API_KEY`
from `app.config.settings`. The entity_id is a stable string derived from
the Supabase user_id so we never persist tokens ourselves.
"""
import logging
from datetime import datetime, timedelta, timezone

from app.config import settings

logger = logging.getLogger(__name__)

# Demo / dev entity pre-linked in the Composio dashboard. Overridable via env
# so we can flip to a per-user mapping later without code changes.
DEMO_ENTITY_ID = "pg-test-b7c6148c-1c7a-4915-966c-47decba5b0e6"


def entity_id_for(user_id: str | None = None) -> str:
    """Resolve the Composio entity id.

    During the demo phase this always returns the pre-linked `DEMO_ENTITY_ID`
    so every Flutter client hits the same already-ACTIVE Google Calendar
    connection. To move to per-user mapping, return `f"user_{user_id}"` here.
    """
    return DEMO_ENTITY_ID


def get_oauth_url_for_entity(entity_id: str) -> dict:
    from composio import ComposioToolSet, App

    toolset = ComposioToolSet(api_key=settings.COMPOSIO_API_KEY)
    try:
        req = toolset.get_entity(entity_id).initiate_connection(
            app_name=App.GOOGLECALENDAR,
        )
        return {
            "oauth_url": req.redirectUrl,
            "entity_id": entity_id,
            "connected_account_id": req.connectedAccountId,
        }
    except Exception as e:
        logger.exception("Composio initiate_connection failed for %s", entity_id)
        return {
            "oauth_url": None,
            "entity_id": entity_id,
            "error": str(e),
        }


def is_entity_connected(entity_id: str) -> bool:
    """Return True iff the entity has an ACTIVE Google Calendar connection."""
    from composio import ComposioToolSet, App

    toolset = ComposioToolSet(api_key=settings.COMPOSIO_API_KEY)
    try:
        conn = toolset.get_entity(entity_id).get_connection(app=App.GOOGLECALENDAR)
        status = getattr(conn, "status", None)
        return str(status).upper() == "ACTIVE"
    except Exception:
        # No connection yet, or still INITIATED.
        return False


def fetch_events_for_entity(entity_id: str, hours: int = 12) -> list[dict]:
    from composio import ComposioToolSet, Action

    toolset = ComposioToolSet(api_key=settings.COMPOSIO_API_KEY)
    try:
        now = datetime.now(timezone.utc)
        end = now + timedelta(hours=hours)
        response = toolset.execute_action(
            action=Action.GOOGLECALENDAR_FIND_EVENT,
            params={
                "calendarId": "primary",
                "timeMin": now.isoformat(),
                "timeMax": end.isoformat(),
                "maxResults": 20,
                "singleEvents": True,
                "orderBy": "startTime",
            },
            entity_id=entity_id,
        )
        data = response if isinstance(response, dict) else {}
        inner = data.get("data") or data.get("response_data") or data
        items: list = []
        if isinstance(inner, dict):
            # Composio wraps Google's `items` in `event_data.event_data`.
            ev = inner.get("event_data")
            if isinstance(ev, dict):
                items = ev.get("event_data") or ev.get("items") or []
            elif isinstance(ev, list):
                items = ev
            if not items:
                items = inner.get("items") or inner.get("events") or []
        elif isinstance(inner, list):
            items = inner

        events = []
        for item in items:
            if not isinstance(item, dict):
                continue
            start = item.get("start", {})
            end_t = item.get("end", {})
            events.append({
                "title": item.get("summary", "Untitled"),
                "start_time": start.get("dateTime") or start.get("date", ""),
                "end_time": end_t.get("dateTime") or end_t.get("date", ""),
                "location": item.get("location"),
                "description": item.get("description"),
            })
        return events
    except Exception:
        logger.exception("Failed to fetch calendar events for entity_id=%s", entity_id)
        return []
