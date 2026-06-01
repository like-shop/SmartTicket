import datetime
import json
import asyncio


from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.task import TicketTask
from app.models.order import TaskExecution, CaptchaRequest, Order
from app.core.engine.browser_pool import browser_pool
from app.core.engine.platforms import get_strategy
from app.core.engine.captcha_handler import captcha_handler
from app.core.websocket.manager import ws_manager
from app.utils.crypto import decrypt_password


class PurchaseRunner:
    async def run(self, task_id: int, attempt_number: int = 1):
        db: Session = SessionLocal()
        task = db.query(TicketTask).filter(TicketTask.id == task_id).first()
        if not task:
            db.close()
            return

        if task.status in ("completed", "cancelled"):
            db.close()
            return

        execution = TaskExecution(
            task_id=task.id,
            status="running",
            attempt_number=attempt_number,
        )
        db.add(execution)
        db.commit()
        db.refresh(execution)

        user_id = task.user_id
        account = task.platform_account

        platform_name = account.platform.name if account.platform else "damai"
        strategy = get_strategy(platform_name)

        instance = None

        try:
            await ws_manager.broadcast_task_status(user_id, task.id, "monitoring")
            task.status = "monitoring"

            if task.scheduled_job_id:
                # Task was scheduled; create monitor execution record
                if not hasattr(self, '_monitor_stage_complete'):
                    pass

            execution.status = "running"
            db.commit()

            await ws_manager.broadcast_task_log(
                user_id, task.id, "INFO", f"正在获取浏览器实例..."
            )

            instance = await browser_pool.acquire(user_id, platform_name)
            if not instance:
                raise Exception("No browser instance available")

            execution.browser_session_id = instance.session_id
            db.commit()

            password = decrypt_password(account.encrypted_password)

            # Step 1: Login
            await ws_manager.broadcast_task_log(user_id, task.id, "INFO", f"正在登录 {platform_name}...")
            login_ok = await strategy.login(instance.driver, account.account_username, password)
            if not login_ok:
                raise Exception("登录失败，请检查账号密码")

            await ws_manager.broadcast_task_log(user_id, task.id, "INFO", "登录成功")

            # Step 2: Navigate to show page
            await ws_manager.broadcast_task_log(user_id, task.id, "INFO", "正在进入演出页面...")
            nav_ok = await strategy.navigate_to_show(instance.driver, task.show_url)
            if not nav_ok:
                raise Exception("无法进入演出页面")

            # Step 3: Wait for sale (monitor phase)
            await ws_manager.broadcast_task_log(user_id, task.id, "INFO", "正在监控开售状态...")
            try:
                await strategy.wait_for_sale(instance.driver, timeout_seconds=120)
            except TimeoutError:
                raise Exception("开售超时，未检测到购票按钮")

            # Step 4: Select ticket
            await ws_manager.broadcast_task_status(user_id, task.id, "purchasing")
            task.status = "purchasing"
            db.commit()

            await ws_manager.broadcast_task_log(user_id, task.id, "INFO", f"正在选择票档: {task.ticket_type}, 数量: {task.quantity}")
            select_ok = await strategy.select_ticket(instance.driver, task.ticket_type, task.quantity)
            if not select_ok:
                raise Exception("选择票档失败")

            # Step 5: Check for captcha after ticket selection
            captcha_found = await self._check_and_handle_captcha(
                strategy, instance, execution, user_id, task.id, db
            )

            # Step 6: Fill purchaser info
            await ws_manager.broadcast_task_log(user_id, task.id, "INFO", "正在填写购票信息...")
            fill_ok = await strategy.fill_purchaser_info(instance.driver)
            if not fill_ok:
                raise Exception("填写购票信息失败")

            # Step 7: Check for captcha before submit
            captcha_found2 = await self._check_and_handle_captcha(
                strategy, instance, execution, user_id, task.id, db
            )

            # Step 8: Submit order
            await ws_manager.broadcast_task_log(user_id, task.id, "INFO", "正在提交订单...")
            result = await strategy.submit_order(instance.driver)

            if result.get("success"):
                execution.status = "completed"
                execution.result_json = json.dumps(result)
                execution.finished_at = datetime.datetime.now(datetime.timezone.utc)
                db.commit()

                order = Order(
                    user_id=user_id,
                    task_id=task.id,
                    task_execution_id=execution.id,
                    platform_account_id=account.id,
                    order_number=result.get("order_number", ""),
                    show_name=task.show_name,
                    ticket_type=task.ticket_type,
                    quantity=task.quantity,
                )
                db.add(order)
                db.commit()
                db.refresh(order)

                task.status = "completed"
                db.commit()

                await ws_manager.broadcast_task_status(user_id, task.id, "completed")
                await ws_manager.broadcast_order_success(
                    user_id, task.id, order.id, order.order_number
                )
                await ws_manager.broadcast_task_log(
                    user_id, task.id, "INFO", f"抢票成功! 订单号: {order.order_number}"
                )

                # 跳转到 12306 官网
                try:
                    await asyncio.to_thread(instance.driver.get, "https://www.12306.cn")
                    await ws_manager.broadcast_task_log(
                        user_id, task.id, "INFO", "已跳转到 12306 官网"
                    )
                except Exception:
                    pass
            else:
                raise Exception(result.get("message", "订单提交失败"))

        except Exception as e:
            error_msg = str(e)
            execution.status = "failed"
            execution.error_message = error_msg
            execution.finished_at = datetime.datetime.now(datetime.timezone.utc)
            db.commit()

            task.status = "failed"
            db.commit()

            await ws_manager.broadcast_task_status(user_id, task.id, "failed")
            await ws_manager.broadcast_task_error(user_id, task.id, error_msg)
            await ws_manager.broadcast_task_log(user_id, task.id, "ERROR", f"抢票失败: {error_msg}")

        finally:
            if instance:
                await browser_pool.release(user_id, instance)
            db.close()

    async def _check_and_handle_captcha(
        self, strategy, instance, execution, user_id, task_id, db
    ) -> bool:
        selectors = strategy.get_captcha_selectors()

        for captcha_type in ["image", "slider"]:
            try:
                img_element = instance.driver.find_element(
                    "css selector", selectors.get(captcha_type, "")
                )
                if img_element and img_element.is_displayed():
                    image_base64 = img_element.screenshot_as_base64

                    captcha_req = CaptchaRequest(
                        task_execution_id=execution.id,
                        captcha_type=captcha_type,
                        captcha_image_base64=image_base64,
                        status="pending",
                    )
                    db.add(captcha_req)
                    db.commit()
                    db.refresh(captcha_req)

                    await ws_manager.broadcast_task_log(
                        user_id, task_id, "INFO", f"检测到{captcha_type}验证码，等待用户输入..."
                    )

                    answer = await captcha_handler.detect_and_wait_for_answer(
                        captcha_req.id, captcha_type, image_base64, user_id, task_id
                    )

                    if answer:
                        captcha_req.user_answer = answer
                        captcha_req.status = "solved"
                        captcha_req.resolved_at = datetime.datetime.now(datetime.timezone.utc)
                        db.commit()

                        # Try to fill captcha input
                        try:
                            input_el = instance.driver.find_element(
                                "css selector", selectors.get("input", "")
                            )
                            input_el.clear()
                            input_el.send_keys(answer)
                            await asyncio.sleep(0.3)

                            # Click verify/submit button
                            try:
                                verify_btn = instance.driver.find_element(
                                    "css selector", ".captcha-submit, .verify-submit"
                                )
                                verify_btn.click()
                                await asyncio.sleep(1)
                            except Exception:
                                pass
                        except Exception:
                            pass

                        await ws_manager.broadcast_task_log(
                            user_id, task_id, "INFO", "验证码已提交"
                        )
                        return True
                    else:
                        captcha_req.status = "timeout"
                        db.commit()
                        raise Exception("验证码超时未输入")

            except Exception:
                continue

        return False


purchase_runner = PurchaseRunner()
