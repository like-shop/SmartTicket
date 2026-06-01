from abc import ABC, abstractmethod


class PlatformStrategy(ABC):
    platform_id: str = ""
    platform_name: str = ""

    @abstractmethod
    async def login(self, driver, username: str, password: str) -> bool:
        """登录到票务平台"""

    @abstractmethod
    async def navigate_to_show(self, driver, show_url: str) -> bool:
        """导航到演出页面"""

    @abstractmethod
    async def wait_for_sale(self, driver, timeout_seconds: int = 120) -> bool:
        """监控页面直到开售"""

    @abstractmethod
    async def select_ticket(self, driver, ticket_type: str, quantity: int) -> bool:
        """选择票档和数量"""

    @abstractmethod
    async def fill_purchaser_info(self, driver) -> bool:
        """填写购票人信息"""

    @abstractmethod
    async def submit_order(self, driver) -> dict:
        """提交订单, 返回结果 dict"""

    @abstractmethod
    def get_captcha_selectors(self) -> dict:
        """返回验证码检测选择器"""
