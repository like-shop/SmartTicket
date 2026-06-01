import json
import datetime

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        self.user_connections: dict[int, list[WebSocket]] = {}
        self.task_subscriptions: dict[int, set[int]] = {}

    async def connect(self, user_id: int, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.user_connections:
            self.user_connections[user_id] = []
        self.user_connections[user_id].append(websocket)
        print(f"[WS] User {user_id} connected ({len(self.user_connections[user_id])} connections)")

    def disconnect(self, user_id: int, websocket: WebSocket):
        if user_id in self.user_connections:
            try:
                self.user_connections[user_id].remove(websocket)
            except ValueError:
                pass
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]
        print(f"[WS] User {user_id} disconnected")

    def subscribe_task(self, user_id: int, task_id: int):
        if user_id not in self.task_subscriptions:
            self.task_subscriptions[user_id] = set()
        self.task_subscriptions[user_id].add(task_id)

    async def send_to_user(self, user_id: int, message: dict):
        payload = json.dumps(message)
        connections = self.user_connections.get(user_id, [])
        dead = []
        for ws in connections:
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(user_id, ws)

    async def broadcast_task_status(self, user_id: int, task_id: int, status: str):
        await self.send_to_user(user_id, {
            "type": "task_status",
            "task_id": task_id,
            "new_status": status,
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        })

    async def broadcast_task_log(self, user_id: int, task_id: int, level: str, message: str):
        await self.send_to_user(user_id, {
            "type": "task_log",
            "task_id": task_id,
            "level": level,
            "message": message,
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        })

    async def broadcast_captcha_require(
        self, user_id: int, task_id: int, captcha_id: int, image_base64: str, captcha_type: str
    ):
        await self.send_to_user(user_id, {
            "type": "captcha_require",
            "task_id": task_id,
            "captcha_id": captcha_id,
            "captcha_image_base64": image_base64,
            "captcha_type": captcha_type,
        })

    async def broadcast_order_success(self, user_id: int, task_id: int, order_id: int, order_number: str):
        await self.send_to_user(user_id, {
            "type": "order_success",
            "task_id": task_id,
            "order_id": order_id,
            "order_number": order_number,
        })

    async def broadcast_task_error(self, user_id: int, task_id: int, error: str):
        await self.send_to_user(user_id, {
            "type": "task_error",
            "task_id": task_id,
            "error": error,
        })

    async def broadcast_ticket_available(self, user_id: int, task_id: int,
                                          train_code: str, seat_type: str, count: str):
        await self.send_to_user(user_id, {
            "type": "ticket_available",
            "task_id": task_id,
            "train_code": train_code,
            "seat_type": seat_type,
            "count": count,
            "message": f"车次 {train_code} {seat_type} 有票了！(余票: {count})",
        })


ws_manager = ConnectionManager()
