from sqlalchemy.orm import Session

from app.models.platform import TicketPlatform


def get_active_platforms(db: Session) -> list[TicketPlatform]:
    return db.query(TicketPlatform).filter(TicketPlatform.is_active == True).all()


def get_platform_by_name(db: Session, name: str) -> TicketPlatform | None:
    return db.query(TicketPlatform).filter(TicketPlatform.name == name).first()


def seed_default_platforms(db: Session):
    defaults = [
        {"name": "train_12306", "display_name": "12306 高铁", "base_url": "https://www.12306.cn"},
    ]
    for p in defaults:
        existing = db.query(TicketPlatform).filter(TicketPlatform.name == p["name"]).first()
        if not existing:
            db.add(TicketPlatform(**p))
    db.commit()
