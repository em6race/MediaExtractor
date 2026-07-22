@echo off
setlocal
chcp 65001 >nul

:: Copy this file to a temp folder to execute as a PowerShell script
set "ps1=%temp%\media_extract_%random%.ps1"
copy /y "%~f0" "%ps1%" >nul

:: Run PowerShell code located below the #PS_START label
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = @(Get-Content -Path '%ps1%' -Encoding UTF8); $idx = [array]::IndexOf($s, '#PS_START'); if ($idx -ge 0) { iex ($s[$idx..$s.Length] -join [Environment]::NewLine) }"

del "%ps1%"
pause
goto :eof

#PS_START
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

$photoExts = @('.jpg','.jpeg','.png','.gif','.bmp','.tiff','.raw','.webp','.heic')
$videoExts = @('.mp4','.avi','.mkv','.mov','.wmv','.flv','.webm','.m4v')
$exts = $photoExts + $videoExts

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Media Extractor Script                                 " -ForegroundColor Cyan
Write-Host "   With logs, chunking, year sorting, and media type      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$copyChoice = Read-Host "Do you want to COPY files instead of moving them? (Y/N)"
$isCopy = ($copyChoice -match '^[Yy]')
if ($isCopy) {
    Write-Host "-> Files will be COPIED. Original files will remain untouched." -ForegroundColor Green
} else {
    Write-Host "-> Files will be MOVED. Original files will be removed from the source folder." -ForegroundColor Green
}

$splitChoice = Read-Host "Do you want to split the saved files into parts by size? (Y/N)"
$maxSize = [long]::MaxValue
$isSplitting = $false

if ($splitChoice -match '^[Yy]') {
    $sizeInput = Read-Host "Enter the maximum size for each part in Gigabytes (e.g., 5, 10, 16) or 0 for no splitting"
    $sizeGB = 0
    if ([int]::TryParse($sizeInput, [ref]$sizeGB) -and $sizeGB -gt 0) {
        $maxSize = $sizeGB * 1024L * 1024L * 1024L
        $isSplitting = $true
        Write-Host "-> Files will be split into parts of up to $sizeGB GB." -ForegroundColor Green
    } else {
        Write-Host "-> Files will NOT be split." -ForegroundColor Green
    }
} else {
    Write-Host "-> Files will NOT be split." -ForegroundColor Green
}

$sortChoice = Read-Host "Do you want to sort files into subfolders by Year? (Y/N)"
$isSorting = ($sortChoice -match '^[Yy]')
if ($isSorting) {
    Write-Host "-> Files will be sorted by Year." -ForegroundColor Green
} else {
    Write-Host "-> Files will NOT be sorted by Year." -ForegroundColor Green
}

Write-Host ""
Write-Host "Please select a folder in the popup window..." -ForegroundColor Yellow

$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select the folder with old files to clean"

$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$result = $folderBrowser.ShowDialog($form)

if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Folder selection cancelled." -ForegroundColor Red
    exit
}

$targetDir = $folderBrowser.SelectedPath
if ($targetDir.Length -le 3) {
    Write-Host "Error: Cannot select an entire drive! Please select a specific folder." -ForegroundColor Red
    exit
}

$parentDir = Split-Path $targetDir -Parent
$folderName = Split-Path $targetDir -Leaf
$saveBaseDir = Join-Path $parentDir "Saved_Media_$folderName"

$currentPart = 1
$currentSize = 0L

Write-Host "Scanning for photos and videos in $targetDir ..." -ForegroundColor Cyan

$filesToMove = @(Get-ChildItem -Path $targetDir -Recurse -Force | Where-Object { 
    -not $_.PSIsContainer -and ($exts -contains $_.Extension.ToLower()) 
})

$totalFiles = $filesToMove.Count
if ($totalFiles -eq 0) {
    Write-Host "No media files found." -ForegroundColor Yellow
    exit
}

$totalBytes = 0L
foreach ($f in $filesToMove) { $totalBytes += $f.Length }

Write-Host "Photos and videos found: $totalFiles" -ForegroundColor Green
Write-Host "Total size: $([math]::Round($totalBytes / 1MB, 2)) MB" -ForegroundColor Green
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
try {
    $uiTop = [Console]::CursorTop - 12
    [Console]::CursorVisible = $false
} catch {
    $uiTop = 0
}

$spinnerChars = @('|', '/', '-', '\')
$spinnerIdx = 0
$lastProcessed = @()

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$movedBytes = 0L

foreach ($file in $filesToMove) {
    # Splitting logic
    if (($currentSize + $file.Length) -gt $maxSize -and $currentSize -gt 0) {
        $currentPart++
        $currentSize = 0L
    }

    if ($isSplitting) {
        $baseDestDir = Join-Path $saveBaseDir "Part_$currentPart"
    } else {
        $baseDestDir = Join-Path $saveBaseDir "All_Media"
    }

    $ext = $file.Extension.ToLower()
    if ($photoExts -contains $ext) {
        $mediaType = "Photos"
    } elseif ($videoExts -contains $ext) {
        $mediaType = "Videos"
    } else {
        $mediaType = "Other"
    }

    # Sorting by Year logic
    if ($isSorting) {
        # Use the oldest date between CreationTime and LastWriteTime for better accuracy with photos
        if ($file.CreationTime -lt $file.LastWriteTime) {
            $dateToUse = $file.CreationTime
        } else {
            $dateToUse = $file.LastWriteTime
        }
        $year = $dateToUse.Year
        if ($year -lt 1980 -or $year -gt 2050) { $year = "Unknown_Year" }
        
        $partDir = Join-Path $baseDestDir "$year\$mediaType"
    } else {
        $partDir = Join-Path $baseDestDir $mediaType
    }

    if (-not (Test-Path $partDir)) {
        New-Item -ItemType Directory -Path $partDir -Force | Out-Null
    }

    $baseName = $file.BaseName
    $extension = $file.Extension
    $destPath = Join-Path $partDir $file.Name
    
    $counter = 1
    # Duplicate protection
    while (Test-Path $destPath) {
        $destPath = Join-Path $partDir "$baseName`_$counter$extension"
        $counter++
    }

    try {
        if ($isCopy) {
            Copy-Item -Path $file.FullName -Destination $destPath -Force
        } else {
            Move-Item -Path $file.FullName -Destination $destPath -Force
        }
        $movedBytes += $file.Length
        $currentSize += $file.Length
    } catch {
        Write-Host "Transfer error: $($file.FullName)" -ForegroundColor Red
    }
    
    # Calculate ETA
    $elapsed = $stopwatch.Elapsed.TotalSeconds
    $speed = if ($elapsed -gt 0) { $movedBytes / $elapsed } else { 0 }
    
    $etaStr = "--:--"
    if ($speed -gt 0) {
        $etaSeconds = ($totalBytes - $movedBytes) / $speed
        $ts = [timespan]::FromSeconds($etaSeconds)
        if ($ts.Hours -gt 0) {
            $etaStr = "{0:D2}:{1:D2}:{2:D2}" -f $ts.Hours, $ts.Minutes, $ts.Seconds
        } else {
            $etaStr = "{0:D2}:{1:D2}" -f $ts.Minutes, $ts.Seconds
        }
    }
    
    # Create text progress bar
    $percent = if ($totalBytes -gt 0) { [math]::Floor(($movedBytes / $totalBytes) * 100) } else { 100 }
    if ($percent -gt 100) { $percent = 100 }
    $filled = [math]::Round(($percent / 100) * 20)
    if ($filled -lt 0) { $filled = 0 }
    if ($filled -gt 20) { $filled = 20 }
    $empty = 20 - $filled
    $bar = ("#" * $filled) + ("-" * $empty)
    
    # Add to last processed array
    $lastProcessed += $file.Name
    if ($lastProcessed.Count -gt 7) {
        $lastProcessed = $lastProcessed[1..7]
    }
    
    # Color logic
    if ($percent -lt 34) { $barColor = "Red" }
    elseif ($percent -lt 67) { $barColor = "Yellow" }
    else { $barColor = "Green" }
    
    $spinChar = $spinnerChars[$spinnerIdx % 4]
    $spinnerIdx++
    
    # Draw UI
    try {
        [Console]::SetCursorPosition(0, $uiTop)
        
        Write-Host "Starting transfer...                                        " -ForegroundColor Cyan
        Write-Host "--------------------------------------------------------    " -ForegroundColor Cyan
        
        Write-Host "[$spinChar] $percent% [" -NoNewline -ForegroundColor Cyan
        Write-Host $bar -NoNewline -ForegroundColor $barColor
        Write-Host "] ETA: $etaStr | Total: $totalFiles        " -ForegroundColor Cyan
        
        Write-Host "--------------------------------------------------------    " -ForegroundColor Cyan
        Write-Host "Recently processed (Last 7):                                " -ForegroundColor Cyan
        
        for ($i = 0; $i -lt 7; $i++) {
            if ($i -lt $lastProcessed.Count) {
                $name = $lastProcessed[$i]
                if ($name.Length -gt 50) { $name = $name.Substring(0, 47) + "..." }
                $name = $name.PadRight(52)
                Write-Host "  > $name" -ForegroundColor Green
            } else {
                Write-Host "                                                        "
            }
        }
    } catch {
        # Fallback if console manipulation fails (e.g., redirected output)
        Write-Host "[$spinChar] $percent% | ETA: $etaStr | File: $($file.Name)" -ForegroundColor Cyan
    }
}

try { [Console]::CursorVisible = $true } catch {}
$stopwatch.Stop()

Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Transfer completed!" -ForegroundColor Green
Write-Host "All your files have been saved to: $saveBaseDir" -ForegroundColor Yellow
if ($isSplitting -and $currentPart -gt 1) {
    Write-Host "Files were automatically split into $currentPart part(s)." -ForegroundColor Magenta
}

if (-not $isCopy) {
    Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "WARNING: Only junk files remain in the old folder ($targetDir)." -ForegroundColor Red
    Write-Host "Type 'Y' and press Enter to DELETE junk files PERMANENTLY." -ForegroundColor Yellow

    $response = Read-Host "Delete junk files? (Y/N)"
    if ($response -match '^[Yy]') {
        Write-Host "Deleting junk..." -ForegroundColor Cyan
        Remove-Item -Path $targetDir -Recurse -Force
        Write-Host "Junk successfully deleted!" -ForegroundColor Green
    } else {
        Write-Host "Deletion cancelled. The old folder has been kept." -ForegroundColor Yellow
    }
}
