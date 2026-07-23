# 📁 Media Extractor

A script that scans a folder full of junk, pulls out all photos and videos, and neatly organizes them — with a real-time progress bar and ETA right in the terminal.

## ⬇️ Download

| System | File |
|--------|------|
| 🪟 Windows 7 / 8 / 10 / 11 | [`MediaExtractor.bat`](https://raw.githubusercontent.com/em6race/MediaExtractor/main/MediaExtractor.bat) |
| 🍎 macOS / 🐧 Linux | [`MediaExtractor.sh`](https://raw.githubusercontent.com/em6race/MediaExtractor/main/MediaExtractor.sh) |

> Just download the one file you need. Everything else is handled automatically.

---

## ✨ Features

- **Copy or Move** — choose whether to keep the originals untouched or move everything
- **Split by size** — automatically split output into parts (e.g. for flash drives)
- **Sort by year** — optionally organize files into subfolders by year
- **Archive support** — optionally extract photos/videos from `.zip`, `.rar`, `.7z`, `.tar` archives (even archives inside archives, one level deep)
- **Auto-download archiver** — if no archiver is installed and you need one, the script downloads a tiny portable tool (~600 KB) automatically and removes it when done
- **Live progress bar** — shows real-time progress, speed, and ETA in the terminal
- **Duplicate protection** — skips files that already exist with the same size
- **Safe cleanup** — asks for confirmation before permanently deleting the original folder

## 🗂️ Supported formats

**Photos:** `.jpg` `.jpeg` `.png` `.gif` `.bmp` `.tiff` `.tif` `.raw` `.cr2` `.nef` `.orf` `.sr2` `.dng` `.psd` `.webp` `.heic` `.avif` `.jp2` `.ico`

**Videos:** `.mp4` `.avi` `.mkv` `.mov` `.wmv` `.flv` `.webm` `.m4v` `.3gp` `.mpg` `.mpeg` `.m2ts` `.mts` `.ts` `.vob` `.rm` `.rmvb` `.asf` `.divx`

**Archives (optional):** `.zip` `.rar` `.7z` `.tar`

---

## 🚀 How to use

### Windows 🪟
1. Download `MediaExtractor.bat`
2. Double-click to run

### macOS 🍎 / Linux 🐧
1. Download `MediaExtractor.sh`
2. Open Terminal and run:
```bash
chmod +x MediaExtractor.sh
./MediaExtractor.sh
```

### What happens next
The script asks you a few quick questions:
1. **Copy or Move?** — `Y` to copy (keep originals), `N` to move
2. **Split into parts?** — `Y` to split by size (e.g. for flash drives)
3. **Sort by year?** — `Y` to sort into year subfolders
4. **Process archives?** — `Y` to also extract photos from `.zip` / `.rar` / `.7z` archives
5. **Select folder** — a folder picker window opens (or type the path)

The output is saved next to your selected folder as `Saved_Media_[FolderName]_[Timestamp]/`.
