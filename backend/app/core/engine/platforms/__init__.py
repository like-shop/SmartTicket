from app.core.engine.platforms.train_12306 import Train12306Strategy

STRATEGY_MAP = {
    "train_12306": Train12306Strategy,
}


def get_strategy(platform_name: str) -> "PlatformStrategy":
    strategy_cls = STRATEGY_MAP.get(platform_name)
    if not strategy_cls:
        raise ValueError(f"Unknown platform: {platform_name}")
    return strategy_cls()
