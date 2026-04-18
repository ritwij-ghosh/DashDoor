import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.meal import MealTemplate
from app.models.user import User
from app.routers.auth import get_current_user
from app.schemas.meal import MealTemplateCreate, MealTemplateResponse, MealTemplateUpdate

router = APIRouter(prefix="/meals", tags=["meals"])


@router.post("/templates", response_model=MealTemplateResponse, status_code=status.HTTP_201_CREATED)
async def create_template(
    data: MealTemplateCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MealTemplateResponse:
    template = MealTemplate(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        name=data.name,
        description=data.description,
        restaurant_name=data.restaurant_name,
        order_url=data.order_url,
        calories=data.calories,
        tags=",".join(data.tags) if data.tags else None,
    )
    db.add(template)
    await db.commit()
    await db.refresh(template)
    return MealTemplateResponse.from_orm_model(template)


@router.get("/templates", response_model=list[MealTemplateResponse])
async def list_templates(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[MealTemplateResponse]:
    result = await db.execute(
        select(MealTemplate)
        .where(MealTemplate.user_id == current_user.id)
        .order_by(MealTemplate.created_at.desc())
    )
    templates = result.scalars().all()
    return [MealTemplateResponse.from_orm_model(t) for t in templates]


@router.get("/templates/{template_id}", response_model=MealTemplateResponse)
async def get_template(
    template_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MealTemplateResponse:
    result = await db.execute(
        select(MealTemplate).where(
            MealTemplate.id == template_id,
            MealTemplate.user_id == current_user.id,
        )
    )
    template = result.scalar_one_or_none()
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Meal template not found")
    return MealTemplateResponse.from_orm_model(template)


@router.put("/templates/{template_id}", response_model=MealTemplateResponse)
async def update_template(
    template_id: str,
    data: MealTemplateUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> MealTemplateResponse:
    result = await db.execute(
        select(MealTemplate).where(
            MealTemplate.id == template_id,
            MealTemplate.user_id == current_user.id,
        )
    )
    template = result.scalar_one_or_none()
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Meal template not found")

    if data.name is not None:
        template.name = data.name
    if data.description is not None:
        template.description = data.description
    if data.restaurant_name is not None:
        template.restaurant_name = data.restaurant_name
    if data.order_url is not None:
        template.order_url = data.order_url
    if data.calories is not None:
        template.calories = data.calories
    if data.tags is not None:
        template.tags = ",".join(data.tags) if data.tags else None

    await db.commit()
    await db.refresh(template)
    return MealTemplateResponse.from_orm_model(template)


@router.delete("/templates/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_template(
    template_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    result = await db.execute(
        select(MealTemplate).where(
            MealTemplate.id == template_id,
            MealTemplate.user_id == current_user.id,
        )
    )
    template = result.scalar_one_or_none()
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Meal template not found")
    await db.delete(template)
    await db.commit()
