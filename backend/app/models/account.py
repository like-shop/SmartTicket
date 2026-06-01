from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, func
from sqlalchemy.orm import relationship

from app.database import Base


class PlatformAccount(Base):
    __tablename__ = "platform_accounts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    platform_id = Column(Integer, ForeignKey("ticket_platforms.id"), nullable=False)
    account_label = Column(String(100), default="")
    account_username = Column(String(100), nullable=False)
    encrypted_password = Column(Text, nullable=False)
    cookies_json = Column(Text, default="{}")
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    last_verified_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    platform = relationship("TicketPlatform", lazy="joined")
