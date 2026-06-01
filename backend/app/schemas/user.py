import datetime
from pydantic import BaseModel


class SendCodeRequest(BaseModel):
    phone: str


class PhoneLogin(BaseModel):
    phone: str
    code: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenRefresh(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: int
    phone: str
    nickname: str
    avatar: str
    is_active: bool
    created_at: datetime.datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    phone: str | None = None
    nickname: str | None = None
    avatar: str | None = None
