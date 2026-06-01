import datetime
from pydantic import BaseModel

from app.schemas.account import AccountResponse


class TaskCreate(BaseModel):
    platform_account_id: int
    show_name: str
    show_url: str
    target_date: str | None = None
    sale_time: str
    ticket_type: str = ""
    quantity: int = 1
    status: str = "pending"
    extra_config: dict | None = None


class TaskUpdate(BaseModel):
    show_name: str | None = None
    show_url: str | None = None
    ticket_type: str | None = None
    quantity: int | None = None
    extra_config: dict | None = None


class TaskResponse(BaseModel):
    id: int
    user_id: int
    platform_account_id: int
    show_name: str
    show_url: str
    target_date: datetime.date | None
    sale_time: datetime.datetime
    ticket_type: str
    quantity: int
    status: str
    priority: int
    extra_config_json: str
    created_at: datetime.datetime
    updated_at: datetime.datetime
    platform_account: AccountResponse | None = None

    model_config = {"from_attributes": True}


class CaptchaSolveRequest(BaseModel):
    answer: str
