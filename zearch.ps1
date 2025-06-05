$scriptFolder = $PSScriptRoot
$dataFolder = Join-Path $scriptFolder "data"
$configPath = Join-Path $scriptFolder "config.json"
$indexFile = Join-Path $dataFolder "zDriveContents.txt"
$indexMetaFile = Join-Path $dataFolder "index_metadata.json"
$instructionsFile = Join-Path $scriptFolder "instructions.txt"

if (!(Test-Path $dataFolder)) {
    New-Item -Path $dataFolder -ItemType Directory | Out-Null
}

function Get-IndexMetadata {
    if (Test-Path $indexMetaFile) {
        $metadata = Get-Content $indexMetaFile | ConvertFrom-Json
        return $metadata
    }
    if (Test-Path $indexFile) {
        try {
            $fileCount = (Get-Content $indexFile -ErrorAction Stop).Count
            $metadata = @{
                directory = $directory
                lastUpdated = "Unknown (pre-existing index)"
                fileCount = $fileCount
            }
            $metadata | ConvertTo-Json | Set-Content $indexMetaFile -Encoding UTF8
            return $metadata
        } catch {
            Write-Host "[!] Found existing index file but cannot read it. It might be locked."
            return $null
        }
    }
    return $null
}

function Test-FileLock {
    param ([string]$path)
    try {
        $file = [System.IO.File]::Open($path, 'Open', 'Read', 'None')
        $file.Close()
        return $false
    } catch {
        return $true
    }
}

function Save-IndexMetadata {
    param ([string]$directory, [string]$lastUpdated)
    $metadata = @{
        directory = $directory
        lastUpdated = $lastUpdated
        fileCount = (Get-Content $indexFile -ErrorAction SilentlyContinue).Count
    } | ConvertTo-Json
    $metadata | Set-Content $indexMetaFile -Encoding UTF8
}

function New-Index {
    param ([string]$directory)
    if (Test-FileLock $indexFile) {
        Write-Host ""; Write-Host "[!] The index file is currently locked. Please close any applications that might be using it."
        Write-Host "    File path: $indexFile"
        $retry = Read-Host "Would you like to retry? (Y/N)"
        if ($retry -eq 'Y') {
            if (Test-FileLock $indexFile) {
                Write-Host "[X] File is still locked. Exiting."
                exit
            }
        } else {
            exit
        }
    }

    Write-Host ""; Write-Host "Indexing $directory..."
    $files = Get-ChildItem -Path $directory -Recurse -File -ErrorAction SilentlyContinue
    $total = $files.Count
    $counter = 0

    try {
        "" | Set-Content -Path $indexFile -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Host ""; Write-Host "[!] Cannot clear existing index file. It might be locked."
        Write-Host "    File path: $indexFile"
        exit
    }

    if ($total -gt 0) {
        foreach ($file in $files) {
            try {
                $file.FullName | Add-Content -Path $indexFile -Encoding UTF8 -ErrorAction Stop
                $counter++
                $percent = [math]::Round(($counter / $total) * 100, 0)
                Write-Progress -Activity "Indexing files..." -Status "$counter of $total" -PercentComplete $percent
            } catch {
                Write-Host ""; Write-Host "[!] Error writing to index file. The file might be locked."
                Write-Host "    File path: $indexFile"
                Write-Host "    Progress: $counter of $total files indexed"
                exit
            }
        }
        Write-Progress -Activity "Indexing files..." -Completed
        Save-IndexMetadata -directory $directory -lastUpdated (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Write-Host ""; Write-Host "Index created successfully with $counter files."
    } else {
        Write-Host ""; Write-Host "No files found in the specified directory."
        Save-IndexMetadata -directory $directory -lastUpdated (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
}

$config = Get-Content $configPath | ConvertFrom-Json
$directory = $config.defaultDirectory
$fallbackUNC = $config.fallbackUNC
$showHelp = $config.showInstructionsOnStart

if ($directory -match '^[A-Z]:$' -and -not (Test-Path $directory)) {
    Write-Host ""; Write-Host "[!] Drive $directory not found. Attempting to map to fallback path $fallbackUNC..."
    & net use $directory $fallbackUNC > $null
    Start-Sleep -Seconds 2
    if (-not (Test-Path $directory)) {
        Write-Host "[X] Failed to access or map $directory. Exiting."
        exit
    }
}

if ($showHelp) {
    Get-Content $instructionsFile | Out-Host
}

$metadata = Get-IndexMetadata
if ($metadata) {
    Write-Host ""; Write-Host "Existing index found:"
    Write-Host "Directory: $($metadata.directory)"
    Write-Host "Last Updated: $($metadata.lastUpdated)"
    Write-Host "Files Indexed: $($metadata.fileCount)"
    $updateChoice = Read-Host ""; Write-Host "Would you like to update the index? (Y/N)"
    if ($updateChoice -eq 'Y') {
        $input = Read-Host "Press [Enter] to update the current default ($directory), or type a valid directory path. Type 'settings' to edit config, or 'help' for instructions."
        $shouldIndex = $true
    } else {
        Write-Host ""; Write-Host "Using existing index for $($metadata.directory)"
        $drive = $metadata.directory
        $shouldIndex = $false
        goto SearchFunction
    }
} else {
    $input = Read-Host "Press [Enter] to search the current default ($directory), or type a valid directory path. Type 'settings' to edit config, or 'help' for instructions."
    $shouldIndex = $true
}

switch ($input.ToLower()) {
    "settings" { notepad $configPath; exit }
    "help" { Get-Content $instructionsFile | Out-Host; exit }
    "" {
        if ([string]::IsNullOrEmpty($directory)) {
            Write-Host "[X] No default directory configured in config.json. Please specify a directory."
            exit
        }
        $drive = $directory
    }
    default {
        if ([string]::IsNullOrEmpty($input)) {
            Write-Host "[X] Invalid directory path. Exiting."
            exit
        }
        $drive = $input
    }
}

if ([string]::IsNullOrEmpty($drive)) {
    Write-Host "[X] No valid directory specified. Exiting."
    exit
}

if (-not (Test-Path $drive)) {
    Write-Host "[X] Directory '$drive' not found. Exiting."
    exit
}

if ($shouldIndex) {
    New-Index -directory $drive
}

:SearchFunction
while ($true) {
    $query = Read-Host ""; Write-Host "Enter search term"
    $matches = Select-String -Path $indexFile -Pattern $query -SimpleMatch | ForEach-Object { $_.Line }

    if ($matches.Count -eq 0) {
        Write-Host "No matches found. Try again."
        continue
    }

    $result = Paginate-Results $matches
    if ($result -eq 'quit') { break }
}

function Show-Loader($msg) {
    $chars = ('|','/','-','\')
    for ($i = 0; $i -lt 10; $i++) {
        $char = $chars[$i % $chars.Length]
        Write-Host -NoNewline "`r$msg $char"
        Start-Sleep -Milliseconds 100
    }
    Write-Host "`r$msg Done.`n"
}

function Paginate-Results {
    param ($results)
    $pageSize = 20
    $page = 0
    $totalPages = [math]::Ceiling($results.Count / $pageSize)

    while ($true) {
        Clear-Host
        $start = $page * $pageSize
        $end = [math]::Min($start + $pageSize - 1, $results.Count - 1)
        Write-Host "Results $(($start+1)) to $(($end+1)) of $($results.Count):`n"

        for ($i = $start; $i -le $end; $i++) {
            Write-Host "$($i+1): $($results[$i])"
        }

        Write-Host "`n[N]ext  [P]rev  [#]Open  [S]earch Again  [H]elp  [Q]uit"
        $choice = Read-Host "Choose"

        switch ($choice.ToLower()) {
            "n" { if ($page -lt $totalPages - 1) { $page++ } }
            "p" { if ($page -gt 0) { $page-- } }
            "s" { return "search" }
            "h" { Get-Content $instructionsFile | Out-Host }
            "q" { return "quit" }
            default {
                if ($choice -match '^[0-9]+$') {
                    $index = [int]$choice - 1
                    if ($index -ge 0 -and $index -lt $results.Count) {
                        Start-Process explorer.exe (Split-Path -Parent $results[$index])
                    }
                }
            }
        }
    }
}
