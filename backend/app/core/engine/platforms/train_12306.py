import asyncio

from app.core.engine.platform_strategy import PlatformStrategy


class Train12306Strategy(PlatformStrategy):
    platform_id = "train_12306"
    platform_name = "12306 高铁"

    async def login(self, driver, username: str, password: str) -> bool:
        try:
            driver.get("https://kyfw.12306.cn/otn/login/init")
            await asyncio.sleep(3)

            username_input = driver.find_element("css selector", 'input[id="J-userName"]')
            password_input = driver.find_element("css selector", 'input[id="J-password"]')

            username_input.clear()
            for ch in username:
                username_input.send_keys(ch)
                await asyncio.sleep(0.05)

            password_input.clear()
            for ch in password:
                password_input.send_keys(ch)
                await asyncio.sleep(0.05)

            login_btn = driver.find_element("css selector", 'a[id="J-login"]')
            login_btn.click()
            await asyncio.sleep(3)

            try:
                driver.find_element("css selector", "#J-header-logout, .header-logout")
                return True
            except Exception:
                return False

        except Exception:
            return False

    async def navigate_to_show(self, driver, show_url: str) -> bool:
        try:
            driver.get(show_url)
            await asyncio.sleep(3)

            query_btn = driver.find_element("css selector", "#query_ticket")
            if query_btn and query_btn.is_displayed():
                query_btn.click()
                await asyncio.sleep(2)

            return True
        except Exception:
            return False

    async def wait_for_sale(self, driver, timeout_seconds: int = 120) -> bool:
        deadline = asyncio.get_event_loop().time() + timeout_seconds

        while asyncio.get_event_loop().time() < deadline:
            try:
                booking_btns = driver.find_elements(
                    "css selector",
                    ".btn72, .yuding, a[onclick*=booking], .booking-btn"
                )
                for btn in booking_btns:
                    if btn.is_displayed() and btn.is_enabled():
                        return True
            except Exception:
                pass

            try:
                no_ticket = driver.find_element("css selector", ".no-ticket, .ticket-none")
                if not no_ticket.is_displayed():
                    return True
            except Exception:
                pass

            await asyncio.sleep(0.3)

        raise TimeoutError("12306 booking button did not appear within timeout")

    async def select_ticket(self, driver, ticket_type: str, quantity: int) -> bool:
        try:
            rows = driver.find_elements("css selector", "tr[id^=ticket_]")
            for row in rows:
                tds = row.find_elements("css selector", "td")
                if len(tds) > 3 and ticket_type in row.text:
                    booking_btn = row.find_element("css selector", "a.yuding, .btn72")
                    booking_btn.click()
                    await asyncio.sleep(1)

                    try:
                        passenger_select = driver.find_element(
                            "css selector", ".ticket-choose .selt, input[name=passenger]"
                        )
                        passenger_select.click()
                        await asyncio.sleep(0.3)
                    except Exception:
                        pass

                    if quantity > 1:
                        try:
                            qty_select = driver.find_element("css selector", "select[name=count]")
                            qty_select.click()
                            await asyncio.sleep(0.2)
                            option = qty_select.find_element(
                                "css selector", f"option[value='{quantity}']"
                            )
                            option.click()
                            await asyncio.sleep(0.2)
                        except Exception:
                            pass

                    return True

            return False

        except Exception:
            return False

    async def fill_purchaser_info(self, driver) -> bool:
        try:
            await asyncio.sleep(2)

            try:
                passenger_cbs = driver.find_elements(
                    "css selector",
                    ".pasnger-list input[type=checkbox]:checked, .passenger-checkbox:checked"
                )
                if not passenger_cbs:
                    first_cb = driver.find_element(
                        "css selector",
                        ".pasnger-list input[type=checkbox], .passenger-checkbox"
                    )
                    first_cb.click()
                    await asyncio.sleep(0.3)
            except Exception:
                pass

            try:
                confirm_btn = driver.find_element(
                    "css selector", "#submitOrder_id, .submit-order, .btn-submit"
                )
                confirm_btn.click()
                await asyncio.sleep(2)
            except Exception:
                pass

            try:
                confirm_dialog_btn = driver.find_element(
                    "css selector", "#qr_submit_id, .qr_submit, .confirm-btn"
                )
                confirm_dialog_btn.click()
                await asyncio.sleep(1)
            except Exception:
                pass

            return True

        except Exception:
            return False

    async def submit_order(self, driver) -> dict:
        try:
            try:
                final_submit = driver.find_element(
                    "css selector",
                    "#confirm_submit, .submitOrder, .btn-pay"
                )
                final_submit.click()
                await asyncio.sleep(3)
            except Exception:
                pass

            current_url = driver.current_url
            order_id = ""

            try:
                order_el = driver.find_element(
                    "css selector",
                    ".order-number, .order-id, .tradeNo"
                )
                order_id = order_el.text.strip()
            except Exception:
                pass

            if "success" in current_url.lower() or "result" in current_url.lower() or order_id:
                return {"success": True, "url": current_url, "order_number": order_id}
            return {"success": False, "message": "Order submission result unclear"}

        except Exception as e:
            return {"success": False, "message": str(e)}

    def get_captcha_selectors(self) -> dict:
        return {
            "image": ".login-img img, .verify-img img, .touclick-img img",
            "input": ".login-answer input, .verify-answer input",
            "slider": ".slide-verify, .nc_wrapper, .touclick-slider",
            "container": ".login-verify, .verify-container, .touclick-wrapper",
        }
