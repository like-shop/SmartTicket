import json
import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.task import TicketTask
from app.models.account import PlatformAccount
from app.schemas.task import TaskCreate, TaskUpdate, TaskResponse, CaptchaSolveRequest
from app.models.order import CaptchaRequest, TaskExecution
from app.api.deps import get_current_user

router = APIRouter()


@router.get("", response_model=list[TaskResponse])
def list_tasks(
    status: str | None = None,
    platform_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(TicketTask).filter(TicketTask.user_id == current_user.id)
    if status:
        q = q.filter(TicketTask.status == status)
    if platform_id:
        q = q.join(PlatformAccount).filter(PlatformAccount.platform_id == platform_id)
    return q.order_by(TicketTask.created_at.desc()).all()


@router.post("", response_model=TaskResponse, status_code=201)
def create_task(
    data: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    account = (
        db.query(PlatformAccount)
        .filter(
            PlatformAccount.id == data.platform_account_id,
            PlatformAccount.user_id == current_user.id,
        )
        .first()
    )
    if not account:
        raise HTTPException(status_code=404, detail="Platform account not found")

    task = TicketTask(
        user_id=current_user.id,
        platform_account_id=data.platform_account_id,
        show_name=data.show_name,
        show_url=data.show_url,
        target_date=datetime.date.fromisoformat(data.target_date) if data.target_date else None,
        sale_time=datetime.datetime.fromisoformat(data.sale_time),
        ticket_type=data.ticket_type,
        quantity=data.quantity,
        status=data.status,
        extra_config_json=json.dumps(data.extra_config or {}),
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.get("/{task_id}", response_model=TaskResponse)
def get_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = (
        db.query(TicketTask)
        .filter(TicketTask.id == task_id, TicketTask.user_id == current_user.id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.put("/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    data: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = (
        db.query(TicketTask)
        .filter(TicketTask.id == task_id, TicketTask.user_id == current_user.id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status != "pending":
        raise HTTPException(status_code=400, detail="Can only update tasks in pending status")

    if data.show_name is not None:
        task.show_name = data.show_name
    if data.show_url is not None:
        task.show_url = data.show_url
    if data.ticket_type is not None:
        task.ticket_type = data.ticket_type
    if data.quantity is not None:
        task.quantity = data.quantity
    if data.extra_config is not None:
        task.extra_config_json = json.dumps(data.extra_config)

    db.commit()
    db.refresh(task)
    return task


@router.delete("/{task_id}", status_code=204)
def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = (
        db.query(TicketTask)
        .filter(TicketTask.id == task_id, TicketTask.user_id == current_user.id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status not in ("pending", "completed", "failed", "cancelled"):
        raise HTTPException(status_code=400, detail="Cancel the task before deleting")

    db.delete(task)
    db.commit()


@router.post("/{task_id}/cancel")
def cancel_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = (
        db.query(TicketTask)
        .filter(TicketTask.id == task_id, TicketTask.user_id == current_user.id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status in ("completed", "failed", "cancelled"):
        raise HTTPException(status_code=400, detail="Task already in terminal state")

    task.status = "cancelled"
    db.commit()
    return {"message": "Task cancelled"}


@router.post("/{task_id}/start")
async def start_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = (
        db.query(TicketTask)
        .filter(TicketTask.id == task_id, TicketTask.user_id == current_user.id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status not in ("pending", "failed"):
        raise HTTPException(status_code=400, detail="Only pending or failed tasks can be started")

    task.status = "pending"
    db.commit()

    from app.core.engine.purchase_runner import purchase_runner
    import asyncio

    asyncio.create_task(purchase_runner.run(task.id))

    return {"message": "Task started", "task_id": task.id}


@router.get("/{task_id}/logs")
def get_task_logs(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = (
        db.query(TicketTask)
        .filter(TicketTask.id == task_id, TicketTask.user_id == current_user.id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    executions = (
        db.query(TaskExecution)
        .filter(TaskExecution.task_id == task_id)
        .order_by(TaskExecution.started_at.desc())
        .limit(20)
        .all()
    )
    return [
        {
            "id": e.id,
            "status": e.status,
            "attempt_number": e.attempt_number,
            "result_json": e.result_json,
            "error_message": e.error_message,
            "started_at": e.started_at.isoformat() if e.started_at else None,
            "finished_at": e.finished_at.isoformat() if e.finished_at else None,
        }
        for e in executions
    ]


@router.post("/{task_id}/captcha/{captcha_id}/solve")
def solve_captcha(
    task_id: int,
    captcha_id: int,
    data: CaptchaSolveRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    captcha = db.query(CaptchaRequest).filter(CaptchaRequest.id == captcha_id).first()
    if not captcha:
        raise HTTPException(status_code=404, detail="Captcha request not found")

    captcha.status = "solved"
    captcha.user_answer = data.answer
    captcha.resolved_at = datetime.datetime.now(datetime.timezone.utc)
    db.commit()

    # Notify the waiting engine via the captcha handler
    from app.core.engine.captcha_handler import captcha_handler

    captcha_handler.submit_answer(captcha_id, data.answer)

    return {"message": "Captcha answer submitted"}
