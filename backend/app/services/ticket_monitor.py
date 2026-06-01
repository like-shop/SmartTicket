import re
import datetime
import asyncio

from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.task import TicketTask
from app.core.websocket.manager import ws_manager
from app.api.v1.train_12306 import check_ticket_availability


class TicketMonitor:
    def __init__(self, interval_seconds: int = 30):
        self.interval = interval_seconds
        self._running = False
        self._task = None

    async def start(self):
        self._running = True
        self._task = asyncio.create_task(self._loop())

    async def _loop(self):
        while self._running:
            try:
                await self._check_all()
            except Exception:
                pass
            await asyncio.sleep(self.interval)

    def stop(self):
        self._running = False
        if self._task:
            self._task.cancel()

    async def _check_all(self):
        db = SessionLocal()
        try:
            tasks = db.query(TicketTask).filter(TicketTask.status == "monitoring").all()
            for task in tasks:
                try:
                    await self._check_one(task, db)
                except Exception:
                    pass
        finally:
            db.close()

    async def _check_one(self, task: TicketTask, db: Session):
        info = _parse_task_info(task.show_name, task.ticket_type)
        if not info:
            return

        result = await asyncio.to_thread(
            check_ticket_availability,
            train_code=info["train_code"],
            from_station=info["from_station"],
            to_station=info["to_station"],
            date=task.target_date.isoformat() if task.target_date else datetime.date.today().isoformat(),
            seat_type=info["seat_type"],
        )

        if result and result.get("available"):
            await ws_manager.broadcast_ticket_available(
                user_id=task.user_id,
                task_id=task.id,
                train_code=info["train_code"],
                seat_type=info["seat_type"],
                count=result.get("count", "有票"),
            )
            task.status = "available"
            db.commit()


def _parse_task_info(show_name: str, seat_type: str) -> dict | None:
    """Parse show_name like 'G123 北京-上海' into train_code, from_station, to_station."""
    m = re.match(r"(\w\d+)\s+(.+?)-(.+)", show_name)
    if not m:
        return None
    return {
        "train_code": m.group(1),
        "from_station": m.group(2),
        "to_station": m.group(3),
        "seat_type": seat_type,
    }


ticket_monitor = TicketMonitor(interval_seconds=30)
