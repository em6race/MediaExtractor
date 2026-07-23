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

$photoExts = @('.jpg','.jpeg','.png','.gif','.bmp','.tiff','.tif','.raw','.cr2','.nef','.orf','.sr2','.dng','.psd','.webp','.heic','.avif','.jp2','.ico')
$videoExts = @('.mp4','.avi','.mkv','.mov','.wmv','.flv','.webm','.m4v','.3gp','.mpg','.mpeg','.m2ts','.mts','.ts','.vob','.rm','.rmvb','.asf','.divx')
$mediaExts = $photoExts + $videoExts
$archiveExts = @('.zip', '.rar', '.7z', '.tar')

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Media Extractor Script                                 " -ForegroundColor Cyan
Write-Host "   With logs, chunking, year sorting, and media type      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] " -NoNewline -ForegroundColor Yellow
$copyChoice = Read-Host "Do you want to COPY files instead of moving them? (Y/N, default N)"
$isCopy = ($copyChoice -match '^[Yy]')
if ($isCopy) {
    Write-Host "-> Files will be COPIED. Original files will remain untouched." -ForegroundColor Green
} else {
    Write-Host "-> Files will be MOVED. Original files will be removed from the source folder." -ForegroundColor Green
}

Write-Host "[2/5] " -NoNewline -ForegroundColor Yellow
$splitChoice = Read-Host "Do you want to split the saved files into parts by size? (Y/N, default N)"
$maxSize = [long]::MaxValue
$isSplitting = $false

if ($splitChoice -match '^[Yy]') {
    Write-Host "[3/5] " -NoNewline -ForegroundColor Yellow
    $sizeInput = Read-Host "Enter the maximum size for each part in Gigabytes (e.g., 5, 10, 16)"
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

Write-Host "[4/5] " -NoNewline -ForegroundColor Yellow
$sortChoice = Read-Host "Do you want to sort files into subfolders by Year? (Y/N, default N)"
$isSorting = ($sortChoice -match '^[Yy]')
if ($isSorting) {
    Write-Host "-> Files will be sorted by Year." -ForegroundColor Green
} else {
    Write-Host "-> Files will NOT be sorted by Year." -ForegroundColor Green
}

Write-Host "[5/5] " -NoNewline -ForegroundColor Yellow
$archiveChoice = Read-Host "Do you want to extract and process media from archives? (Y/N, default N)"
$processArchives = ($archiveChoice -match '^[Yy]')
if ($processArchives) {
    Write-Host "-> Archives will be processed." -ForegroundColor Green
} else {
    Write-Host "-> Archives will be IGNORED." -ForegroundColor Green
}

if ($processArchives) {
    $exts = $mediaExts + $archiveExts
} else {
    $exts = $mediaExts
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
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$saveBaseDir = Join-Path $parentDir "Saved_Media_$folderName`_$timestamp"

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

# --- Pre-download archiver if needed ---
$script:portable7zr = $null
if ($processArchives) {
    $hasArchiver = (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") -or
                   (Test-Path "${env:ProgramFiles(x86)}\7-Zip\7z.exe") -or
                   (Test-Path "$env:ProgramFiles\WinRAR\WinRAR.exe")
    if (-not $hasArchiver) {
        $toolsDir = Join-Path $saveBaseDir ".temp_tools"
        New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
        $script:portable7zr = Join-Path $toolsDir "7zr.exe"
        if (-not (Test-Path $script:portable7zr)) {
            Write-Host ""
            Write-Host "  No archiver found on this PC." -ForegroundColor Yellow
            Write-Host "  Downloading portable 7zr.exe (~600 KB) from repo..." -ForegroundColor Yellow
            $url = "https://raw.githubusercontent.com/em6race/MediaExtractor/main/tools/7zr.exe"
            $dlDone = $false
            $dlOk = $false
            try {
                $wc = New-Object System.Net.WebClient
                $wc.add_DownloadProgressChanged({
                    param($s, $e)
                    $pct = $e.ProgressPercentage
                    $filled = [int]($pct / 5)
                    $empty = 20 - $filled
                    $bar = ("#" * $filled) + ("-" * $empty)
                    $dlKB = [math]::Round($e.BytesReceived / 1KB)
                    $totalKB = [math]::Round($e.TotalBytesToReceive / 1KB)
                    Write-Host "`r  Downloading: [$bar] $pct% ($dlKB KB / $totalKB KB)   " -NoNewline -ForegroundColor Cyan
                })
                $wc.add_DownloadFileCompleted({
                    param($s, $e)
                    $script:dlDone = $true
                    $script:dlOk = ($null -eq $e.Error -and -not $e.Cancelled)
                })
                $script:dlDone = $false
                $script:dlOk = $false
                $wc.DownloadFileAsync([uri]$url, $script:portable7zr)
                while (-not $script:dlDone) { Start-Sleep -Milliseconds 100 }
                Write-Host ""
                if ($script:dlOk) {
                    Write-Host "  Download complete! Will be removed after processing." -ForegroundColor Green
                } else {
                    Write-Host "  Download failed. RAR/7z archives will be skipped." -ForegroundColor Red
                    $script:portable7zr = $null
                }
            } catch {
                # Fallback for older PowerShell
                try {
                    Write-Host "`r  Downloading..." -NoNewline -ForegroundColor Cyan
                    Invoke-WebRequest -Uri $url -OutFile $script:portable7zr -UseBasicParsing
                    Write-Host " Done!" -ForegroundColor Green
                } catch {
                    Write-Host " Failed. RAR/7z archives will be skipped." -ForegroundColor Red
                    $script:portable7zr = $null
                }
            }
        } else {
            Write-Host "  Using cached portable 7zr.exe." -ForegroundColor Cyan
        }
        Write-Host ""
    }
}
# --- End pre-download ---

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
$lastUiUpdate = [DateTime]::Now

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$movedBytes = 0L

$queue = New-Object System.Collections.Generic.Queue[PSCustomObject]
foreach ($f in $filesToMove) {
    $queue.Enqueue([pscustomobject]@{ File = $f; Depth = 0; IsTemp = $false })
}

while ($queue.Count -gt 0) {
    $item = $queue.Dequeue()
    $file = $item.File
    $depth = $item.Depth
    $isTemp = $item.IsTemp
    
    $ext = $file.Extension.ToLower()


    if ($archiveExts -contains $ext) {
        if ($depth -le 1) {
            try {
                [Console]::SetCursorPosition(0, $uiTop)
                Write-Host "Extracting $($file.Name)...                                        " -ForegroundColor Magenta
            } catch {}
            
            $tempDirName = [guid]::NewGuid().ToString()
            $tempPath = Join-Path $saveBaseDir ".temp_extract\$tempDirName"
            New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
            
            $success = $false
            if ($ext -eq '.zip') {
                try { Expand-Archive -Path $file.FullName -DestinationPath $tempPath -Force -ErrorAction Stop; $success = $true } catch {}
            } elseif ($ext -eq '.tar') {
                try { tar -xf $file.FullName -C $tempPath; if ($LASTEXITCODE -eq 0) { $success = $true } } catch {}
            } elseif ($ext -eq '.rar' -or $ext -eq '.7z') {
                # Find 7-Zip or WinRAR, or download portable 7zr.exe from repo
                $exe = $null
                if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
                    $exe = "$env:ProgramFiles\7-Zip\7z.exe"
                } elseif (Test-Path "${env:ProgramFiles(x86)}\7-Zip\7z.exe") {
                    $exe = "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
                } elseif (Test-Path "$env:ProgramFiles\WinRAR\WinRAR.exe") {
                    $exe = "$env:ProgramFiles\WinRAR\WinRAR.exe"
                } else {
                    # Use pre-downloaded portable 7zr.exe (downloaded before main loop)
                    if ($script:portable7zr -and (Test-Path $script:portable7zr)) {
                        $exe = $script:portable7zr
                    }
                }
                
                if ($exe) {
                    $argStr = "x `"$($file.FullName)`" -o`"$tempPath`" -y -p-"
                    $proc = Start-Process -FilePath $exe -ArgumentList $argStr -Wait -NoNewWindow -PassThru
                    if ($proc.ExitCode -eq 0) { $success = $true }
                }
            }
            
            if ($success) {
                $extractedFiles = @(Get-ChildItem -Path $tempPath -Recurse -Force | Where-Object { 
                    -not $_.PSIsContainer -and ($exts -contains $_.Extension.ToLower()) 
                })
                foreach ($ef in $extractedFiles) {
                    $queue.Enqueue([pscustomobject]@{ File = $ef; Depth = ($depth + 1); IsTemp = $true })
                    $totalBytes += $ef.Length
                    $totalFiles++
                }
                $totalBytes -= $file.Length
                $totalFiles--
                
                if (-not $isCopy -and -not $isTemp) {
                    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                }
                continue
            }
        }
        
        $archiveDir = Join-Path $saveBaseDir "Archives"
        if (-not (Test-Path $archiveDir)) {
            New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
        }
        $destPath = Join-Path $archiveDir $file.Name
        $skipFile = $false
        $counter = 1
        while (Test-Path $destPath) {
            $existingFile = Get-Item $destPath
            if ($existingFile.Length -eq $file.Length) { $skipFile = $true; break }
            $destPath = Join-Path $archiveDir "$baseName`_$counter$extension"
            $counter++
        }
        
        if ($skipFile) {
            $movedBytes += $file.Length
            if (-not $isCopy -and -not $isTemp) { Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue }
        } else {
            try {
                if ($isCopy -and -not $isTemp) { Copy-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue }
                else { Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue }
                $movedBytes += $file.Length
                $currentSize += $file.Length
            } catch {}
        }
    } else {
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

    $destPath = Join-Path $partDir $file.Name

    
    $skipFile = $false
    $counter = 1
    # Duplicate protection with exact size match
    while (Test-Path $destPath) {
        $existingFile = Get-Item $destPath
        if ($existingFile.Length -eq $file.Length) {
            $skipFile = $true
            break
        }
        $destPath = Join-Path $partDir "$baseName`_$counter$extension"
        $counter++
    }

    if ($skipFile) {
        $movedBytes += $file.Length
        if (-not $isCopy) {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
        }
        continue
    }

    try {
        if ($isCopy -and -not $isTemp) {
            Copy-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
        } else {
            Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
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
    $now = [DateTime]::Now
    if (($now - $lastUiUpdate).TotalMilliseconds -gt 100 -or $movedBytes -eq $totalBytes) {
        $lastUiUpdate = $now
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
}

}

try { [Console]::CursorVisible = $true } catch {}
$stopwatch.Stop()

Remove-Item -Path (Join-Path $saveBaseDir ".temp_extract") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $saveBaseDir ".temp_tools") -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Transfer completed!" -ForegroundColor Green
Write-Host "All your files have been saved to: $saveBaseDir" -ForegroundColor Yellow
if ($isSplitting -and $currentPart -gt 1) {
    Write-Host "Files were automatically split into $currentPart part(s)." -ForegroundColor Magenta
}

if (-not $isCopy) {
    Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "WARNING: Only junk files remain in the old folder ($targetDir)." -ForegroundColor Red
    Write-Host "[6/6] Do you want to permanently delete the original folder (containing only junk)? (Y/N, default N): " -NoNewline -ForegroundColor Yellow

    $response = Read-Host ""
    if ($response -match '^[Yy]') {
        Write-Host "Deleting junk..." -ForegroundColor Cyan
        Remove-Item -Path $targetDir -Recurse -Force
        Write-Host "Junk successfully deleted!" -ForegroundColor Green
    } else {
        Write-Host "Deletion cancelled. The old folder has been kept." -ForegroundColor Yellow
    }
}
