from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Date, func
from sqlalchemy.orm import relationship

from app.database import Base


class TicketTask(Base):
    __tablename__ = "ticket_tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    platform_account_id = Column(Integer, ForeignKey("platform_accounts.id"), nullable=False)
    show_name = Column(String(255), nullable=False)
    show_url = Column(String(500), nullable=False)
    target_date = Column(Date, nullable=True)
    sale_time = Column(DateTime, nullable=False)
    ticket_type = Column(String(100), default="")
    quantity = Column(Integer, default=1)
    status = Column(String(20), default="pending", index=True)
    priority = Column(Integer, default=5)
    extra_config_json = Column(Text, default="{}")
    scheduled_job_id = Column(String(100), default="")
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    platform_account = relationship("PlatformAccount", lazy="joined")
    executions = relationship("TaskExecution", back_populates="task", lazy="dynamic")
