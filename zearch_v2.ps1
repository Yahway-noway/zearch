# Zearch! v2 - PowerShell Prototype
# Author: OpenAI Operator
# Description: Command-line utility to index directories, manage indexes, search, and open file locations.
# Designed for easy future porting to Python.

param(
    [switch]$Help
)

if ($Help) {
    Write-Host "Zearch! v2 - Usage:" -ForegroundColor Yellow
    Write-Host "Run the script and follow on‑screen prompts to index, search, or manage indexes." 
    exit
}

# -------------------- Config & Globals --------------------
$Script:IndexFolder = Join-Path $PSScriptRoot "indexes"
$Script:ConfigPath  = Join-Path $PSScriptRoot "config.json"

if (-not (Test-Path $IndexFolder)) {
    New-Item -ItemType Directory -Path $IndexFolder | Out-Null
}

function Get-Config {
    if (Test-Path $ConfigPath) {
        try { return Get-Content $ConfigPath | ConvertFrom-Json } catch { }
    }
    # default config
    return [pscustomobject]@{
        DefaultDirectory = $HOME
        RecentIndex      = $null
        StartupMode      = "menu"
    }
}

function Save-Config($cfg) {
    $cfg | ConvertTo-Json -Depth 3 | Set-Content $ConfigPath
}

$Config = Get-Config

# -------------------- Indexing --------------------
function Build-Index {
    param(
        [string]$TargetDir,
        [string]$FriendlyName,
        [switch]$UpdateExisting
    )

    $indexPath = Join-Path $IndexFolder ("{0}.txt" -f ($FriendlyName -replace "[^a-zA-Z0-9_-]", "").ToLower())

    if (Test-Path $indexPath -and -not $UpdateExisting) {
        Write-Warning "Index '$FriendlyName' already exists. Use update option."
        return
    }

    if ($UpdateExisting -and (Test-Path $indexPath)) {
        if (-not (Confirm-Action "Overwrite existing index '$FriendlyName'?")) { return }
        if (-not (Confirm-Action "Really overwrite? This cannot be undone.")) { return }
    }

    Write-Host "Building index... this may take a moment." -ForegroundColor Cyan
    try {
        Get-ChildItem -Path $TargetDir -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName |
            Set-Content -Path $indexPath
        Write-Host "Index saved to $indexPath" -ForegroundColor Green
    } catch {
        Write-Error "Failed to build index: $_"
    }
}

# -------------------- Utilities --------------------
function Confirm-Action {
    param([string]$Message)
    $resp = Read-Host "$Message [y/N]"
    return $resp -match '^(y|yes)$'
}

function List-Indexes {
    Get-ChildItem -Path $IndexFolder -Filter '*.txt' | Select-Object -ExpandProperty Name
}

function Choose-Index {
    $indexes = List-Indexes
    if (-not $indexes) { Write-Host "No indexes found."; return $null }
    for ($i=0; $i -lt $indexes.Count; $i++) {
        Write-Host "[$($i+1)] $($indexes[$i])"
    }
    $choice = Read-Host "Select index number"
    if ($choice -as [int] -and $choice -ge 1 -and $choice -le $indexes.Count) {
        return $indexes[$choice-1]
    }
    Write-Warning "Invalid selection."
    return $null
}

function Search-Index {
    param([string]$IndexFile)

    $indexPath = Join-Path $IndexFolder $IndexFile
    if (-not (Test-Path $indexPath)) { Write-Warning "Index not found."; return }

    $term = Read-Host "Enter search term (regex supported)"
    $matches = Select-String -Path $indexPath -Pattern $term

    if (-not $matches) { Write-Host "No matches."; return }

    $i = 1
    foreach ($m in $matches) {
        Write-Host "[$i] $($m.Line)"; $i++
    }

    $sel = Read-Host "Enter result number to open (or blank to cancel)"
    if ($sel -as [int] -and $sel -ge 1 -and $sel -le $matches.Count) {
        $path = $matches[$sel-1].Line
        if (Test-Path $path) {
            Write-Host "Opening location..." -ForegroundColor Cyan
            Start-Process explorer.exe "/select,`"$path`""
        } else {
            Write-Warning "File no longer exists."
        }
    }
}

# -------------------- Main Menu --------------------
function Main-Menu {
    while ($true) {
        Write-Host "\n=== Zearch! Main Menu ===" -ForegroundColor Yellow
        $indexes = List-Indexes
        if ($indexes) {
            Write-Host "Existing indexes:"; $indexes | ForEach-Object { Write-Host " - $_" }
        } else {
            Write-Host "(No indexes yet)"
        }
        Write-Host "\n[L]oad index to search"
        Write-Host "[A]dd new index"
        Write-Host "[U]pdate existing index"
        Write-Host "[D]elete index"
        Write-Host "[S]ettings"
        Write-Host "[Q]uit"
        $input = Read-Host "Choose option (or 'help')"
        switch ($input.ToLower()) {
            'l' {
                $idx = Choose-Index
                if ($idx) { Search-Index -IndexFile $idx }
            }
            'a' {
                $dir = Read-Host "Directory to index (default: $($Config.DefaultDirectory))"
                if (-not $dir) { $dir = $Config.DefaultDirectory }
                if (-not (Test-Path $dir)) { Write-Warning "Invalid path."; break }
                $name = Read-Host "Friendly name for index"
                if ($name) { Build-Index -TargetDir $dir -FriendlyName $name }
            }
            'u' {
                $idx = Choose-Index
                if ($idx) {
                    $dir = Read-Host "Directory to re-index (leave blank to use same)"
                    if (-not $dir) { $dir = $Config.DefaultDirectory }
                    Build-Index -TargetDir $dir -FriendlyName ($idx -replace '.txt$','') -UpdateExisting
                }
            }
            'd' {
                $idx = Choose-Index
                if ($idx) {
                    if (Confirm-Action "Delete index '$idx'?") {
                        if (Confirm-Action "Really delete? This cannot be undone.") {
                            Remove-Item (Join-Path $IndexFolder $idx)
                            Write-Host "Deleted." -ForegroundColor Red
                        }
                    }
                }
            }
            's' {
                Write-Host "Current settings:" -ForegroundColor Cyan
                $Config | Format-List
                if (Confirm-Action "Edit default directory?") {
                    $newDir = Read-Host "Enter new default directory path"
                    if (Test-Path $newDir) { $Config.DefaultDirectory = $newDir; Save-Config $Config }
                }
            }
            'help' { Write-Host "Type the letter inside brackets to choose an action. Each action has its own help inside prompts." }
            'q' { break }
            default { Write-Warning "Unknown option." }
        }
    }
}

# -------------------- Run --------------------
Main-Menu
