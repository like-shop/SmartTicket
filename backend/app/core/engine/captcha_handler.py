import asyncio

from app.config import settings


class CaptchaHandler:
    def __init__(self):
        self._pending_events: dict[int, asyncio.Event] = {}
        self._captcha_answers: dict[int, str] = {}
        self.timeout = settings.CAPTCHA_TIMEOUT_SECONDS

    def submit_answer(self, captcha_id: int, answer: str):
        self._captcha_answers[captcha_id] = answer
        event = self._pending_events.get(captcha_id)
        if event:
            event.set()

    async def detect_and_wait_for_answer(
        self, captcha_id: int, captcha_type: str, image_base64: str, user_id: int, task_id: int
    ) -> str | None:
        from app.core.websocket.manager import ws_manager

        self._pending_events[captcha_id] = asyncio.Event()

        await ws_manager.broadcast_captcha_require(
            user_id, task_id, captcha_id, image_base64, captcha_type
        )

        try:
            await asyncio.wait_for(
                self._pending_events[captcha_id].wait(), timeout=self.timeout
            )
        except asyncio.TimeoutError:
            self._pending_events.pop(captcha_id, None)
            return None

        self._pending_events.pop(captcha_id, None)
        return self._captcha_answers.pop(captcha_id, None)


captcha_handler = CaptchaHandler()
