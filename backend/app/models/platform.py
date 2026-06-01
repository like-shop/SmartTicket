from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, func

from app.database import Base


class TicketPlatform(Base):
    __tablename__ = "ticket_platforms"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False)
    display_name = Column(String(100), nullable=False)
    base_url = Column(String(255), nullable=False)
    logo_url = Column(String(500), default="")
    is_active = Column(Boolean, default=True)
    login_config_json = Column(Text, default="{}")
    purchase_config_json = Column(Text, default="{}")
    created_at = Column(DateTime, server_default=func.now())
