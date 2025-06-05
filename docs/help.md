# Zearch Help

Zearch is a command‑line utility for indexing the contents of a drive and searching that index offline.

## Commands

### `index`
Build or refresh the index.

```bash
zearch index [-d DRIVE]
```

* `-d`, `--drive` &mdash; Root path to index (defaults to your system drive).

### `search`
Search the existing index for a filename or pattern.

```bash
zearch search PATTERN
```

## Examples

```bash
# Index the C: drive
zearch index -d C:\

# Find any PDF named invoice
zearch search invoice.pdf
```

## Files Generated

| File | Purpose |
|------|---------|
| `data/zdrivecontents.txt` | List of every file path found. |
| `data/index_metadata.json` | Metadata about the index (drive, file count). |

## Installation

```bash
pip install -e .
```

After installation you can call `zearch` directly from the terminal.
