import datetime
from decimal import Decimal
from pydantic import BaseModel


class OrderResponse(BaseModel):
    id: int
    user_id: int
    task_id: int | None
    task_execution_id: int | None
    order_number: str
    show_name: str
    ticket_type: str
    seat_info: str
    quantity: int
    unit_price: Decimal
    total_price: Decimal
    status: str
    created_at: datetime.datetime

    model_config = {"from_attributes": True}
