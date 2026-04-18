import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.recommendation import UserLocation
from app.models.user import User
from app.routers.auth import get_current_user
from app.schemas.recommendation import LocationCreate, LocationResponse

router = APIRouter(prefix="/location", tags=["location"])


@router.post("", response_model=LocationResponse, status_code=status.HTTP_200_OK)
async def upsert_location(
    location_data: LocationCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> LocationResponse:
    """Create or update the user's current location."""
    result = await db.execute(
        select(UserLocation).where(UserLocation.user_id == current_user.id)
    )
    existing = result.scalar_one_or_none()

    if existing:
        existing.city = location_data.city
        existing.address = location_data.address
        existing.travel_note = location_data.travel_note
        existing.updated_at = datetime.now(timezone.utc)
        await db.commit()
        await db.refresh(existing)
        return LocationResponse.model_validate(existing)
    else:
        new_location = UserLocation(
            id=str(uuid.uuid4()),
            user_id=current_user.id,
            city=location_data.city,
            address=location_data.address,
            travel_note=location_data.travel_note,
            updated_at=datetime.now(timezone.utc),
        )
        db.add(new_location)
        await db.commit()
        await db.refresh(new_location)
        return LocationResponse.model_validate(new_location)


@router.get("", response_model=LocationResponse)
async def get_location(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> LocationResponse:
    """Get the user's current saved location."""
    result = await db.execute(
        select(UserLocation).where(UserLocation.user_id == current_user.id)
    )
    location = result.scalar_one_or_none()
    if not location:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No location set. Please POST to /location first.",
        )
    return LocationResponse.model_validate(location)
