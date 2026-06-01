from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Numeric, func
from sqlalchemy.orm import relationship

from app.database import Base


class TaskExecution(Base):
    __tablename__ = "task_executions"

    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("ticket_tasks.id"), nullable=False)
    status = Column(String(20), default="running")
    attempt_number = Column(Integer, default=1)
    browser_session_id = Column(String(100), default="")
    result_json = Column(Text, default="{}")
    error_message = Column(Text, default="")
    started_at = Column(DateTime, server_default=func.now())
    finished_at = Column(DateTime, nullable=True)

    task = relationship("TicketTask", back_populates="executions")
    captcha_requests = relationship("CaptchaRequest", back_populates="execution", lazy="dynamic")


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    task_id = Column(Integer, ForeignKey("ticket_tasks.id"), nullable=True)
    task_execution_id = Column(Integer, ForeignKey("task_executions.id"), nullable=True)
    platform_account_id = Column(Integer, ForeignKey("platform_accounts.id"), nullable=True)
    order_number = Column(String(100), default="")
    show_name = Column(String(255), nullable=False)
    ticket_type = Column(String(100), default="")
    seat_info = Column(String(255), default="")
    quantity = Column(Integer, default=1)
    unit_price = Column(Numeric(10, 2), default=0)
    total_price = Column(Numeric(10, 2), default=0)
    status = Column(String(20), default="confirmed")
    platform_raw_data_json = Column(Text, default="{}")
    created_at = Column(DateTime, server_default=func.now())


class CaptchaRequest(Base):
    __tablename__ = "captcha_requests"

    id = Column(Integer, primary_key=True, index=True)
    task_execution_id = Column(Integer, ForeignKey("task_executions.id"), nullable=False)
    captcha_type = Column(String(50), default="image")
    captcha_image_base64 = Column(Text, default="")
    status = Column(String(20), default="pending")
    user_answer = Column(String(50), default="")
    created_at = Column(DateTime, server_default=func.now())
    resolved_at = Column(DateTime, nullable=True)

    execution = relationship("TaskExecution", back_populates="captcha_requests")
