import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.routers.auth import get_current_user_id
from app.database import get_supabase

router = APIRouter(prefix="/location", tags=["location"])


class LocationCreate(BaseModel):
    city: str
    address: Optional[str] = None
    travel_note: Optional[str] = None


@router.post("")
async def upsert_location(
    body: LocationCreate,
    user_id: str = Depends(get_current_user_id),
) -> dict:
    db = get_supabase()
    db.table("user_locations").upsert(
        {
            "user_id": user_id,
            "city": body.city,
            "address": body.address,
            "travel_note": body.travel_note,
            "updated_at": datetime.datetime.utcnow().isoformat(),
        },
        on_conflict="user_id",
    ).execute()
    return {"message": "Location saved"}


@router.get("")
async def get_location(user_id: str = Depends(get_current_user_id)) -> dict:
    db = get_supabase()
    res = db.table("user_locations").select("*").eq("user_id", user_id).maybe_single().execute()
    data = res.data if res else None
    if not data:
        raise HTTPException(status_code=404, detail="No location set")
    return data
