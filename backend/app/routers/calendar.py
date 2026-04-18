from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
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
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """
    Returns a Composio OAuth URL for the current user to connect Google Calendar.
    Saves the entity_id to the user record.
    """
    try:
        result = await get_calendar_oauth_url(current_user, db)
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


@router.get("/callback")
async def calendar_oauth_callback(
    entity_id: str = Query(..., description="The Composio entity ID (user.id)"),
) -> dict:
    """
    Composio redirects here after the user authorizes Google Calendar.
    Marks the user's calendar as connected.
    """
    await mark_calendar_connected(entity_id)
    return {"message": "Google Calendar connected successfully.", "entity_id": entity_id}


@router.get("/events")
async def list_calendar_events(
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[dict]:
    """
    Fetches upcoming events for the next 12 hours from Google Calendar via Composio.
    Returns [] if calendar not connected or on any error.
    """
    events = await get_upcoming_events(current_user, hours=12)
    return events
