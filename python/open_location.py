"""open_location.py
Cross-platform helper to open the containing folder of a given path in the OS file manager.
"""

from __future__ import annotations
import subprocess
import sys
from pathlib import Path

__all__ = ["open_location"]

def open_location(target: str | Path) -> None:
    """Open the folder containing *target* and highlight the file if supported."""
    path = Path(target).expanduser().resolve()
    if not path.exists():
        raise FileNotFoundError(path)

    if sys.platform.startswith("win"):
        subprocess.Popen(["explorer", f"/select,{path}"])
    elif sys.platform.startswith("darwin"):
        subprocess.Popen(["open", "-R", str(path)])
    else:  # assume Linux / BSD with xdg-open
        subprocess.Popen(["xdg-open", str(path.parent)])
