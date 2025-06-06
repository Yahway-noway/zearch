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

## Python CLI (Cross‑Platform)

Zearch also ships with a lightweight, dependency‑free Python implementation that works on Windows, macOS and Linux.

### Features

* **Interactive menu** for creating, updating, deleting and searching multiple indexes.
* **Regex‑powered search** across indexed file paths.
* **Opens containing folder** for any result directly in your system file explorer.
* **Portable** – pure standard‑library Python (no external packages).

### Requirements

* Python **3.8+**
* Read access to the folders you want to index

### Installation

```bash
# 1. Clone the repository
$ git clone https://github.com/Yahway-noway/zearch.git
$ cd zearch

# 2. (Optional) create & activate a virtual environment
$ python -m venv .venv
$ source .venv/bin/activate  # Windows: .venv\Scripts\activate

# 3. Run the tool
$ python main.py
```

#### Quick install via script

If you prefer a one‑step setup, run the bundled installer:

```bash
./install.sh
```

This will:

1. Copy the Python files to **~/.local/share/zearch** (or a directory you specify).
2. Create a wrapper command at **~/.local/bin/zearch**.
3. Remind you to add that directory to your `PATH` so you can simply type `zearch` from any terminal.

There are **no external dependencies**, so `pip install` is not required.

### Usage

Running `python main.py` presents an interactive menu:

```
=== Zearch (python) ===
[L]oad & search an index
[A]dd new index
[U]pdate existing index
[D]elete index
[S]ettings
[Q]uit
```

#### Create a new index
```
A            # choose **A**dd new index
Directory to index: /path/to/folder
Friendly name for index: work_docs
```
The index (a plain‑text list of file paths) is saved to `indexes/work_docs.txt`.

#### Search an index
```
L            # choose **L**oad & search
Select index: work_docs
Enter search term (regex supported): .*report_2025.*\.xlsx
```
Matching files are displayed with an option to open the folder containing each file.

#### Update or delete
Use **U** to refresh an existing index if files have changed, or **D** to remove an index file.

### Where things are stored

| Path | Purpose |
|------|---------|
| `indexes/` | Folder that holds one `<name>.txt` file per index |
| `config.json` | Stores default directory, exclusions, etc. (auto‑created) |

### Packaging / advanced use
The Python scripts are intentionally simple so you can copy them into other projects or package them with tools like **pipx**:
```bash
pipx run --spec git+https://github.com/Yahway-noway/zearch@main zearch
```

---
