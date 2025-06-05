"""index_manager.py
Manages creation, update, listing, and deletion of index files for Zearch! (Python version).
"""

from __future__ import annotations
import os
import json
from pathlib import Path
from typing import List

# Folder to store index text files (one path per line)
INDEX_DIR = Path(__file__).resolve().parent / "indexes"
INDEX_DIR.mkdir(exist_ok=True)

__all__ = [
    "create_index",
    "update_index",
    "list_indexes",
    "delete_index",
    "get_index_path",
]

def _sanitize(name: str) -> str:
    """Return a filesystem‑safe lowercase name."""
    return "".join(c for c in name.lower() if c.isalnum() or c in ("-", "_"))

def get_index_path(name: str) -> Path:
    return INDEX_DIR / f"{_sanitize(name)}.txt"

def _walk_directory(directory: Path):
    """Yield all file paths under *directory* recursively."""
    for root, _, files in os.walk(directory):
        for f in files:
            yield Path(root) / f

def create_index(directory: str | os.PathLike, name: str) -> Path:
    """Create a new index from *directory* and save under *name*.

    Raises FileExistsError if the index already exists.
    """
    path = get_index_path(name)
    if path.exists():
        raise FileExistsError(f"Index '{name}' already exists: {path}")
    return _write_index(Path(directory), path)

def update_index(directory: str | os.PathLike, name: str) -> Path:
    """Overwrite an existing index with a fresh scan of *directory*."""
    path = get_index_path(name)
    if not path.exists():
        raise FileNotFoundError(f"Index '{name}' does not exist.")
    return _write_index(Path(directory), path)

def _write_index(directory: Path, path: Path) -> Path:
    if not directory.is_dir():
        raise NotADirectoryError(directory)
    with path.open("w", encoding="utf-8") as fh:
        for file_path in _walk_directory(directory):
            fh.write(str(file_path) + "\n")
    return path

def list_indexes() -> List[str]:
    """Return list of index names (without .txt)."""
    return [p.stem for p in INDEX_DIR.glob("*.txt")]

def delete_index(name: str) -> None:
    path = get_index_path(name)
    if path.exists():
        path.unlink()
    else:
        raise FileNotFoundError(name)
