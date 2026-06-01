from app.core.engine.purchase_runner import purchase_runner


class JobExecutor:
    async def execute_monitor_phase(self, task_id: int):
        """Pre-sale monitoring: establish session early so we're ready at sale time."""
        await purchase_runner.run(task_id, attempt_number=1)

    async def execute_purchase_phase(self, task_id: int):
        """Execute the purchase at sale time."""
        await purchase_runner.run(task_id, attempt_number=1)
