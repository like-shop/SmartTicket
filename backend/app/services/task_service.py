import json
import datetime

from sqlalchemy.orm import Session

from app.models.task import TicketTask


def create_ticket_task(
    db: Session,
    user_id: int,
    platform_account_id: int,
    show_name: str,
    show_url: str,
    sale_time: datetime.datetime,
    ticket_type: str = "",
    quantity: int = 1,
    target_date: str = "",
    extra_config: dict | None = None,
) -> TicketTask:
    task = TicketTask(
        user_id=user_id,
        platform_account_id=platform_account_id,
        show_name=show_name,
        show_url=show_url,
        target_date=datetime.date.fromisoformat(target_date) if target_date else None,
        sale_time=sale_time,
        ticket_type=ticket_type,
        quantity=quantity,
        extra_config_json=json.dumps(extra_config or {}),
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


def get_user_tasks(
    db: Session, user_id: int, status: str | None = None, platform_id: int | None = None
):
    q = db.query(TicketTask).filter(TicketTask.user_id == user_id)
    if status:
        q = q.filter(TicketTask.status == status)
    if platform_id:
        from app.models.account import PlatformAccount
        q = q.join(PlatformAccount).filter(PlatformAccount.platform_id == platform_id)
    return q.order_by(TicketTask.created_at.desc()).all()
