from fastapi import APIRouter
from app.api.v1 import platforms, accounts, tasks, orders, websocket, train_12306

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(platforms.router, prefix="/platforms", tags=["platforms"])
api_router.include_router(accounts.router, prefix="/accounts", tags=["accounts"])
api_router.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
api_router.include_router(orders.router, prefix="/orders", tags=["orders"])
api_router.include_router(websocket.router, prefix="/ws", tags=["websocket"])
api_router.include_router(train_12306.router, prefix="/12306", tags=["12306"])
