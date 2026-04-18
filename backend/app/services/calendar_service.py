from datetime import datetime, timedelta, timezone

from app.config import settings


def get_oauth_url_for_entity(entity_id: str) -> dict:
    from composio import ComposioToolSet, App

    toolset = ComposioToolSet(api_key=settings.COMPOSIO_API_KEY)
    try:
        req = toolset.get_entity(entity_id).initiate_connection(app=App.GOOGLECALENDAR)
        return {"oauth_url": req.redirectUrl, "entity_id": entity_id}
    except Exception as e:
        return {"oauth_url": None, "entity_id": entity_id, "error": str(e)}


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
        return []
