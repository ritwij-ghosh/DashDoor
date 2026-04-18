from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    COMPOSIO_API_KEY: str = "ak_uWdQGwzssrkC9YtNDoDm"
    ANTHROPIC_API_KEY: str = ""
    SECRET_KEY: str = "changeme-in-production-use-a-long-random-string"
    DATABASE_URL: str = "sqlite+aiosqlite:///./healthy_autopilot.db"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
