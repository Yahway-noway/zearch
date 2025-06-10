"""config.py
Handles reading and writing a simple JSON config file for Zearch!.
"""

from __future__ import annotations
import json
from pathlib import Path
from typing import Any, Dict

CONFIG_PATH = Path(__file__).resolve().parent / "config.json"

DEFAULT_CONFIG: Dict[str, Any] = {
    "default_directory": str(Path.home()),
    "recent_index": None,
    "startup_mode": "menu",
}

__all__ = ["load_config", "save_config", "CONFIG_PATH"]

def load_config() -> Dict[str, Any]:
    if CONFIG_PATH.exists():
        try:
            return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass  # fall back to default if corrupted
    return DEFAULT_CONFIG.copy()

def save_config(cfg: Dict[str, Any]) -> None:
    CONFIG_PATH.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
