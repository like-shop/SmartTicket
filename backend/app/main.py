from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import engine, Base, SessionLocal
from app.api.v1 import api_router
from app.core.scheduler.scheduler import task_scheduler
from app.core.engine.browser_pool import browser_pool
from app.services.platform_service import seed_default_platforms
from app.services.ticket_monitor import ticket_monitor


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        seed_default_platforms(db)
    finally:
        db.close()

    task_scheduler.start()
    app.state.scheduler = task_scheduler
    app.state.browser_pool = browser_pool
    await ticket_monitor.start()
    print("[SmartTicket] Backend started successfully")

    yield

    # Shutdown
    ticket_monitor.stop()
    task_scheduler.shutdown(wait=True)
    await browser_pool.shutdown()
    print("[SmartTicket] Backend shut down")


app = FastAPI(
    title="SmartTicket API",
    description="自动抢票系统后端 API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/")
def root():
    return {"name": "SmartTicket API", "version": "1.0.0", "status": "running"}
