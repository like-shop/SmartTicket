from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./smartticket.db"
    SECRET_KEY: str = "change-me-in-production-use-a-real-secret-key"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    PLATFORM_PASSWORD_ENCRYPTION_KEY: str = "smartticket-aes-key-32-bytes-here!"

    BROWSER_POOL_MAX_TOTAL: int = 6
    BROWSER_POOL_MAX_PER_USER: int = 3

    CAPTCHA_TIMEOUT_SECONDS: int = 60
    MONITOR_ADVANCE_SECONDS: int = 300

    class Config:
        env_file = ".env"


settings = Settings()
