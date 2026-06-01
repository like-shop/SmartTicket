import json

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query

from app.core.security import decode_token
from app.core.websocket.manager import ws_manager

router = APIRouter()


@router.websocket("")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(default=""),
):
    user_id = 1
    if token:
        payload = decode_token(token)
        if payload and payload.get("type") == "access":
            uid = int(payload.get("sub", 0))
            if uid:
                user_id = uid

    await ws_manager.connect(user_id, websocket)

    try:
        while True:
            raw = await websocket.receive_text()
            message = json.loads(raw)
            msg_type = message.get("type", "")

            if msg_type == "heartbeat_ping":
                await websocket.send_json({"type": "heartbeat_pong"})
            elif msg_type == "subscribe_task":
                task_id = message.get("task_id")
                if task_id:
                    ws_manager.subscribe_task(user_id, task_id)
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
    finally:
        ws_manager.disconnect(user_id, websocket)
