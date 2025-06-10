"""search.py
Provides search functionality over index files produced by Zearch!.
"""

from __future__ import annotations
from pathlib import Path
import re
from typing import List

__all__ = ["search_index"]

def search_index(index_file: str | Path, term: str, *, regex: bool = True, ignore_case: bool = True) -> List[str]:
    """Return list of matching lines from *index_file* that match *term*.

    Parameters
    ----------
    index_file : str | Path
        Path to the .txt index file.
    term : str
        Search term (regex pattern or plain substring).
    regex : bool, default True
        Whether *term* should be treated as a regular expression.
    ignore_case : bool, default True
        Case‑insensitive match if True.
    """
    path = Path(index_file)
    if not path.exists():
        raise FileNotFoundError(path)

    flags = re.IGNORECASE if ignore_case else 0
    pattern = re.compile(term, flags) if regex else None

    matches: List[str] = []
    with path.open("r", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if regex:
                if pattern.search(line):
                    matches.append(line)
            else:
                if (line.lower() if ignore_case else line).find(term.lower() if ignore_case else term) != -1:
                    matches.append(line)
    return matches
