from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from app.models.user import User
from app.routers.auth import get_current_user
from app.services.calendar_service import (
    get_calendar_oauth_url,
    get_upcoming_events,
    mark_calendar_connected,
)

router = APIRouter(prefix="/calendar", tags=["calendar"])


@router.get("/connect")
async def connect_calendar(
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """
    Returns a Composio OAuth URL plus a short-lived confirmation token.

    Mobile flow:
    1) Open oauth_url in an external browser/webview.
    2) After auth success, call POST /calendar/confirm with connect_token.
    """
    try:
        result = await get_calendar_oauth_url(current_user)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Failed to generate calendar connection URL: {str(e)}",
        )


@router.get("/status")
async def calendar_status(
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """Returns whether Google Calendar is connected for the current user."""
    return {"connected": current_user.calendar_connected}


@router.post("/confirm")
async def confirm_calendar_connection(
    connect_token: str,
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    """
    Marks calendar as connected for the authenticated user.
    Requires the one-time connect_token previously returned by /calendar/connect.
    """
    is_connected = await mark_calendar_connected(current_user.id, connect_token)
    if not is_connected:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired calendar connect token.",
        )
    return {"message": "Google Calendar connected successfully.", "connected": True}


@router.get("/events")
async def list_calendar_events(
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[dict]:
    """
    Fetches upcoming events for the next 12 hours from Google Calendar via Composio.
    Returns [] if calendar is not connected or if upstream call fails.
    """
    events = await get_upcoming_events(current_user, hours=12)
    return events
