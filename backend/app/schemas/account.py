import datetime
from pydantic import BaseModel

from app.schemas.platform import PlatformResponse


class AccountCreate(BaseModel):
    platform_id: int
    account_label: str = ""
    account_username: str
    password: str


class AccountUpdate(BaseModel):
    account_label: str | None = None
    account_username: str | None = None
    password: str | None = None


class AccountResponse(BaseModel):
    id: int
    user_id: int
    platform_id: int
    account_label: str
    account_username: str
    is_active: bool
    is_verified: bool
    last_verified_at: datetime.datetime | None
    created_at: datetime.datetime
    platform: PlatformResponse | None = None

    model_config = {"from_attributes": True}
