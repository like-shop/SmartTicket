import datetime

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.date import DateTrigger
from apscheduler.jobstores.memory import MemoryJobStore

from app.config import settings
from app.core.scheduler.job_executor import JobExecutor


class TaskScheduler:
    def __init__(self):
        jobstores = {"default": MemoryJobStore()}
        self.scheduler = AsyncIOScheduler(jobstores=jobstores, timezone=datetime.timezone.utc)
        self.executor = JobExecutor()

    def start(self):
        self.scheduler.start()

    def shutdown(self, wait: bool = True):
        self.scheduler.shutdown(wait=wait)

    def schedule_task(self, task) -> str:
        sale_time = task.sale_time
        if sale_time.tzinfo is None:
            sale_time = sale_time.replace(tzinfo=datetime.timezone.utc)

        # Monitor job: fires MONITOR_ADVANCE_SECONDS before sale time
        monitor_time = sale_time - datetime.timedelta(
            seconds=settings.MONITOR_ADVANCE_SECONDS
        )
        if monitor_time > datetime.datetime.now(datetime.timezone.utc):
            monitor_job_id = f"monitor_{task.id}"
            self.scheduler.add_job(
                self.executor.execute_monitor_phase,
                trigger=DateTrigger(run_date=monitor_time),
                args=[task.id],
                id=monitor_job_id,
                replace_existing=True,
            )

        # Purchase job: fires at exact sale time
        purchase_job_id = f"purchase_{task.id}"
        self.scheduler.add_job(
            self.executor.execute_purchase_phase,
            trigger=DateTrigger(run_date=sale_time),
            args=[task.id],
            id=purchase_job_id,
            replace_existing=True,
        )

        return purchase_job_id

    def cancel_task(self, task_id: int):
        for prefix in ("monitor_", "purchase_"):
            job_id = f"{prefix}{task_id}"
            try:
                self.scheduler.remove_job(job_id)
            except Exception:
                pass

    def get_jobs(self):
        return self.scheduler.get_jobs()


task_scheduler = TaskScheduler()
