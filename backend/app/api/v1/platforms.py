from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.models.platform import TicketPlatform
from app.schemas.platform import PlatformResponse, PlatformDetail
from app.api.deps import get_current_user

router = APIRouter()


@router.get("", response_model=list[PlatformResponse])
def list_platforms(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(TicketPlatform).filter(TicketPlatform.is_active == True).all()


@router.get("/{platform_id}", response_model=PlatformDetail)
def get_platform(
    platform_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    platform = db.query(TicketPlatform).filter(TicketPlatform.id == platform_id).first()
    if not platform:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Platform not found")
    return platform
