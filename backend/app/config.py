from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    SUPABASE_URL: str = ""
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""
    COMPOSIO_API_KEY: str = "ak_uWdQGwzssrkC9YtNDoDm"
    ANTHROPIC_API_KEY: str = ""
    SUPERMEMORY_API_KEY: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}

    @property
    def cors_allow_origins_list(self) -> list[str]:
        return ["*"]


settings = Settings()
