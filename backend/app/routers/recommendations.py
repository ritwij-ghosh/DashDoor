from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.recommendation import Recommendation
from app.models.user import User
from app.routers.auth import get_current_user
from app.schemas.recommendation import RecommendationRequest, RecommendationResponse
from app.services.recommendation_service import generate_recommendations

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


@router.post("/generate", response_model=RecommendationResponse, status_code=status.HTTP_201_CREATED)
async def generate(
    request: RecommendationRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> RecommendationResponse:
    """
    Generates AI meal recommendations for the next 8-12 hours based on the
    user's calendar events, location, and travel context.
    """
    rec = await generate_recommendations(
        user=current_user,
        db=db,
        location_override=request.location,
        travel_override=request.travel_context,
    )
    return RecommendationResponse.from_orm_model(rec)


@router.get("", response_model=list[RecommendationResponse])
async def list_recommendations(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[RecommendationResponse]:
    """Returns the last 10 recommendations for the current user."""
    result = await db.execute(
        select(Recommendation)
        .where(Recommendation.user_id == current_user.id)
        .order_by(Recommendation.generated_at.desc())
        .limit(10)
    )
    recs = result.scalars().all()
    return [RecommendationResponse.from_orm_model(r) for r in recs]


@router.get("/{recommendation_id}", response_model=RecommendationResponse)
async def get_recommendation(
    recommendation_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> RecommendationResponse:
    result = await db.execute(
        select(Recommendation).where(
            Recommendation.id == recommendation_id,
            Recommendation.user_id == current_user.id,
        )
    )
    rec = result.scalar_one_or_none()
    if not rec:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recommendation not found")
    return RecommendationResponse.from_orm_model(rec)
