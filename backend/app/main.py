from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import calendar, chat, location, meals, profile, recommendations

app = FastAPI(
    title="Healthy Autopilot API",
    description="Proactive meal planning around your calendar and location.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_allow_origins_list,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

for router in [calendar.router, chat.router, location.router, meals.router, profile.router, recommendations.router]:
    app.include_router(router, prefix="/api/v1")


@app.get("/health", tags=["health"])
def health() -> dict:
    return {"status": "ok", "version": "2.0.0"}
