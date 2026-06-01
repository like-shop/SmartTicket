import datetime
from pydantic import BaseModel


class PlatformResponse(BaseModel):
    id: int
    name: str
    display_name: str
    base_url: str
    logo_url: str
    is_active: bool
    created_at: datetime.datetime

    model_config = {"from_attributes": True}


class PlatformDetail(PlatformResponse):
    login_config_json: str
    purchase_config_json: str
