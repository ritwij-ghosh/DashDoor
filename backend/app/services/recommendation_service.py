import json
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.recommendation import Recommendation, UserLocation
from app.models.user import User
from app.services.ai_service import generate_meal_plan
from app.services.calendar_service import get_upcoming_events


async def generate_recommendations(
    user: User,
    db: AsyncSession,
    location_override: str | None = None,
    travel_override: str | None = None,
) -> Recommendation:
    # 1. Resolve location
    location_str = location_override
    travel_context = travel_override

    if not location_str:
        result = await db.execute(
            select(UserLocation).where(UserLocation.user_id == user.id)
        )
        saved = result.scalar_one_or_none()
        if saved:
            location_str = saved.city
            if saved.address:
                location_str = f"{saved.address}, {saved.city}"
            if not travel_context and saved.travel_note:
                travel_context = saved.travel_note
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No location set. POST to /api/v1/location or include 'location' in the request body.",
            )

    # 2. Fetch calendar events
    events = await get_upcoming_events(user, hours=12)

    # 3. Generate AI recommendations
    now = datetime.now(timezone.utc)
    ai_result = await generate_meal_plan(
        events=events,
        location=location_str,
        travel_context=travel_context,
        current_time=now,
    )

    # 4. Persist
    window_end = now + timedelta(hours=12)
    rec = Recommendation(
        id=str(uuid.uuid4()),
        user_id=user.id,
        generated_at=now,
        location=location_str,
        travel_context=travel_context,
        calendar_summary=json.dumps(events),
        recommendations_json=json.dumps(ai_result),
        window_start=now,
        window_end=window_end,
    )
    db.add(rec)
    await db.commit()
    await db.refresh(rec)
    return rec
