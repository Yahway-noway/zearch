"""main.py
Interactive CLI entry point for the Python version of Zearch!.
"""

from __future__ import annotations
import sys
from pathlib import Path

from index_manager import (
    create_index,
    update_index,
    list_indexes,
    delete_index,
    get_index_path,
)
from search import search_index
from open_location import open_location
from config import load_config, save_config


def prompt(msg: str) -> str:
    try:
        return input(msg).strip()
    except (EOFError, KeyboardInterrupt):
        print()
        sys.exit(0)

def choose_index() -> str | None:
    indexes = list_indexes()
    if not indexes:
        print("No indexes available.")
        return None
    for i, name in enumerate(indexes, 1):
        print(f"[{i}] {name}")
    choice = prompt("Select index number: ")
    if choice.isdigit() and 1 <= int(choice) <= len(indexes):
        return indexes[int(choice) - 1]
    print("Invalid selection.")
    return None

def confirm(msg: str) -> bool:
    return prompt(f"{msg} [y/N]: ").lower() in {"y", "yes"}

def main() -> None:
    cfg = load_config()

    while True:
        print("\n=== Zearch! (Python) ===")
        print("[L]oad & search index")
        print("[A]dd new index")
        print("[U]pdate existing index")
        print("[D]elete index")
        print("[S]ettings")
        print("[Q]uit")
        choice = prompt("Choose option: ").lower()

        if choice == "l":
            idx = choose_index()
            if idx:
                term = prompt("Enter search term (regex ok): ")
                matches = search_index(get_index_path(idx), term)
                if not matches:
                    print("No matches.")
                    continue
                for i, m in enumerate(matches, 1):
                    print(f"[{i}] {m}")
                sel = prompt("Result number to open (blank to cancel): ")
                if sel.isdigit() and 1 <= int(sel) <= len(matches):
                    open_location(matches[int(sel) - 1])
        elif choice == "a":
            directory = prompt(f"Directory to index (default: {cfg['default_directory']}): ") or cfg["default_directory"]
            if not Path(directory).is_dir():
                print("Invalid directory.")
                continue
            name = prompt("Friendly name for index: ")
            try:
                create_index(directory, name)
                print("Index created.")
            except FileExistsError as e:
                print(e)
        elif choice == "u":
            idx = choose_index()
            if idx:
                directory = prompt("Directory to re-index (leave blank to keep same): ") or cfg["default_directory"]
                try:
                    update_index(directory, idx)
                    print("Index updated.")
                except Exception as e:
                    print(e)
        elif choice == "d":
            idx = choose_index()
            if idx and confirm(f"Delete index '{idx}'?") and confirm("Really delete? This cannot be undone."):
                delete_index(idx)
                print("Deleted.")
        elif choice == "s":
            print("Current settings:")
            for k, v in cfg.items():
                print(f"  {k}: {v}")
            if confirm("Edit default directory?"):
                new_dir = prompt("Enter new default directory: ")
                if Path(new_dir).is_dir():
                    cfg["default_directory"] = new_dir
                    save_config(cfg)
        elif choice == "q":
            break
        else:
            print("Unknown option.")


if __name__ == "__main__":
    main()
