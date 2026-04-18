from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    COMPOSIO_API_KEY: str = ""
    ANTHROPIC_API_KEY: str = ""
    SECRET_KEY: str = ""
    DATABASE_URL: str = "sqlite+aiosqlite:///./healthy_autopilot.db"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    CORS_ALLOW_ORIGINS: str = "*"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}

    @property
    def cors_allow_origins_list(self) -> list[str]:
        parsed = [origin.strip() for origin in self.CORS_ALLOW_ORIGINS.split(",") if origin.strip()]
        return parsed or ["*"]


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
