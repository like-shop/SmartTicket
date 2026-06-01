from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.models.account import PlatformAccount
from app.models.platform import TicketPlatform
from app.schemas.account import AccountCreate, AccountUpdate, AccountResponse
from app.api.deps import get_current_user
from app.utils.crypto import encrypt_password, decrypt_password

router = APIRouter()


@router.get("", response_model=list[AccountResponse])
def list_accounts(
    platform_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    q = db.query(PlatformAccount).filter(PlatformAccount.user_id == current_user.id)
    if platform_id:
        q = q.filter(PlatformAccount.platform_id == platform_id)
    return q.all()


@router.post("", response_model=AccountResponse, status_code=201)
def create_account(
    data: AccountCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    platform = db.query(TicketPlatform).filter(TicketPlatform.id == data.platform_id).first()
    if not platform:
        raise HTTPException(status_code=404, detail="Platform not found")

    account = PlatformAccount(
        user_id=current_user.id,
        platform_id=data.platform_id,
        account_label=data.account_label,
        account_username=data.account_username,
        encrypted_password=encrypt_password(data.password),
    )
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


@router.put("/{account_id}", response_model=AccountResponse)
def update_account(
    account_id: int,
    data: AccountUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    account = (
        db.query(PlatformAccount)
        .filter(PlatformAccount.id == account_id, PlatformAccount.user_id == current_user.id)
        .first()
    )
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")

    if data.account_label is not None:
        account.account_label = data.account_label
    if data.account_username is not None:
        account.account_username = data.account_username
    if data.password is not None:
        account.encrypted_password = encrypt_password(data.password)

    db.commit()
    db.refresh(account)
    return account


@router.delete("/{account_id}", status_code=204)
def delete_account(
    account_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    account = (
        db.query(PlatformAccount)
        .filter(PlatformAccount.id == account_id, PlatformAccount.user_id == current_user.id)
        .first()
    )
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")

    db.delete(account)
    db.commit()


@router.post("/{account_id}/verify")
def verify_account(
    account_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    account = (
        db.query(PlatformAccount)
        .filter(PlatformAccount.id == account_id, PlatformAccount.user_id == current_user.id)
        .first()
    )
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")

    return {"verified": True, "message": "Verification not implemented yet"}
