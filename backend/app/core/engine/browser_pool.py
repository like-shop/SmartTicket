import asyncio
import uuid
from collections import defaultdict

from app.config import settings


class BrowserInstance:
    def __init__(self, driver, session_id: str, user_data_dir: str):
        self.driver = driver
        self.session_id = session_id
        self.user_data_dir = user_data_dir


class BrowserPool:
    def __init__(self, max_total: int = 6, max_per_user: int = 3):
        self.max_total = max_total
        self.max_per_user = max_per_user
        self._user_browsers: dict[int, list[BrowserInstance]] = defaultdict(list)
        self._total_active = 0
        self._lock = asyncio.Lock()
        self._initialized = False

    def _ensure_driver(self):
        """Lazy import undetected_chromedriver to avoid startup errors when not installed."""
        try:
            import undetected_chromedriver as uc
            return uc
        except ImportError:
            raise RuntimeError(
                "undetected-chromedriver is required. Install with: pip install undetected-chromedriver"
            )

    async def acquire(self, user_id: int, platform: str) -> BrowserInstance | None:
        async with self._lock:
            if self._total_active >= self.max_total:
                return None
            if len(self._user_browsers[user_id]) >= self.max_per_user:
                return None

            self._total_active += 1

        try:
            uc = self._ensure_driver()

            session_id = str(uuid.uuid4())[:8]
            import tempfile
            import os

            user_data_dir = os.path.join(tempfile.gettempdir(), f"smartticket_{session_id}")

            options = uc.ChromeOptions()
            options.add_argument(f"--user-data-dir={user_data_dir}")
            options.add_argument("--disable-blink-features=AutomationControlled")
            options.add_argument("--disable-dev-shm-usage")
            options.add_argument("--no-sandbox")
            options.add_argument("--window-size=1366,768")
            options.add_argument("--accept-lang=zh-CN,zh;q=0.9")

            driver = await asyncio.to_thread(uc.Chrome, options=options)
            instance = BrowserInstance(driver, session_id, user_data_dir)

            async with self._lock:
                self._user_browsers[user_id].append(instance)

            return instance
        except Exception:
            async with self._lock:
                self._total_active -= 1
            raise

    async def release(self, user_id: int, instance: BrowserInstance):
        async with self._lock:
            try:
                self._user_browsers[user_id].remove(instance)
            except ValueError:
                pass
            self._total_active -= 1

        try:
            instance.driver.quit()
        except Exception:
            pass

    async def shutdown(self):
        for user_id in list(self._user_browsers.keys()):
            for instance in list(self._user_browsers[user_id]):
                try:
                    instance.driver.quit()
                except Exception:
                    pass
        self._user_browsers.clear()
        self._total_active = 0


browser_pool = BrowserPool(
    max_total=settings.BROWSER_POOL_MAX_TOTAL,
    max_per_user=settings.BROWSER_POOL_MAX_PER_USER,
)
