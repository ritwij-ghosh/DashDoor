from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional

from app.routers.auth import get_current_user_id
from app.database import get_supabase

router = APIRouter(prefix="/profile", tags=["profile"])


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    dietary_preferences: Optional[list[str]] = None
    health_goals: Optional[str] = None
    onboarding_data: Optional[dict] = None


@router.get("")
async def get_profile(user_id: str = Depends(get_current_user_id)) -> dict:
    db = get_supabase()
    res = db.table("profiles").select("*").eq("id", user_id).maybe_single().execute()
    return res.data or {}


@router.put("")
async def update_profile(
    body: ProfileUpdate,
    user_id: str = Depends(get_current_user_id),
) -> dict:
    db = get_supabase()
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    if updates:
        db.table("profiles").update(updates).eq("id", user_id).execute()
    res = db.table("profiles").select("*").eq("id", user_id).maybe_single().execute()
    return res.data or {}
