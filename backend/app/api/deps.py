from fastapi import Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User


def _get_or_create_default_user(db: Session) -> User:
    user = db.query(User).filter(User.phone == "00000000000").first()
    if not user:
        user = User(phone="00000000000", nickname="游客")
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


def get_current_user(db: Session = Depends(get_db)) -> User:
    return _get_or_create_default_user(db)
