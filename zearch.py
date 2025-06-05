#!/usr/bin/env python3
"""Zearch: Drive indexer and search CLI.

Usage:
  zearch index [-d DRIVE]   # build or refresh index
  zearch search PATTERN     # search existing index

Install (editable):
  pip install -e .
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from subprocess import run

DATA_DIR = Path(__file__).with_suffix("").parent / "data"
DATA_DIR.mkdir(exist_ok=True)
INDEX_PATH = DATA_DIR / "zdrivecontents.txt"
META_PATH = DATA_DIR / "index_metadata.json"


def build_index(drive: str) -> None:
    """Walk *drive* and write all file paths to the index."""
    print(f"Building index for {drive} (this may take a while)…")
    count = 0
    with INDEX_PATH.open("w", encoding="utf-8", errors="ignore") as out:
        for root, _dirs, files in os.walk(drive):
            for fname in files:
                out.write(os.path.join(root, fname) + "\n")
                count += 1
    META_PATH.write_text(json.dumps({"drive": drive, "files": count}, indent=2))
    print(f"Index built: {count} files recorded.")


def search_index(pattern: str) -> None:
    """Search the index for *pattern* (case‑insensitive)."""
    if not INDEX_PATH.exists():
        sys.exit("Index not found. Run 'zearch index' first.")

    matches = []
    with INDEX_PATH.open(encoding="utf-8", errors="ignore") as fp:
        for line in fp:
            if pattern.lower() in line.lower():
                matches.append(line.strip())

    for m in matches:
        print(m)
    print(f"{len(matches)} match(es) found.")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Zearch ‑ drive index & search")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_index = sub.add_parser("index", help="Build or refresh the index")
    p_index.add_argument(
        "-d",
        "--drive",
        default=str(Path.home().anchor),
        help="Drive root to index (e.g., C:\\)",
    )

    p_search = sub.add_parser("search", help="Search the index")
    p_search.add_argument("pattern", help="Text to search for in file paths")

    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    if args.cmd == "index":
        build_index(args.drive)
    elif args.cmd == "search":
        search_index(args.pattern)


if __name__ == "__main__":
    main()
