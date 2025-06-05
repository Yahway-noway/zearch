# Zearch

A PowerShell utility that indexes the contents of a drive and lets you perform fast, offline searches against that index.

## Features

- **Index builder**: Scans the target drive and saves a list of every file to `data\zdrivecontents.txt`.
- **Metadata tracking**: Stores index details (directory, file count, last‐updated timestamp) in `data\index_metadata.json`.
- **Configurable**: Reads settings such as drive letter and exclusions from `config.json` (auto‑generated on first run).
- **Search mode**: Quickly searches the saved index for file names or patterns.
- **Self‑documenting**: Writes basic usage instructions to `instructions.txt`.

## Usage

```powershell
# Build or refresh the index (may take a while on first run)
./search.ps1 -Index

# Search the existing index for a filename or pattern
./search.ps1 -Search "report_2025.xlsx"
```

## File overview

| File | Purpose |
|------|---------|
| `search.ps1` | Main script that handles both indexing and searching. |
| `data\zdrivecontents.txt` | Generated list of all file paths. |
| `data\index_metadata.json` | JSON metadata about the current index. |
| `config.json` | Script configuration (drive letter, exclusions, etc.). |
| `instructions.txt` | Auto‑generated quick‑start guide. |

## Requirements

* Windows PowerShell 5.x or PowerShell Core 7+
* Sufficient permissions to read the target drive

## License

MIT — see `LICENSE` (or add one).
