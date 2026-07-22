# Local Media Extractor

A fast, lightweight, and interactive script designed to extract photos and videos from messy, junk-filled folders on old computers. It works entirely offline and uses native OS components for maximum speed and compatibility.

## 🚀 Features
- **Zero Installation**: Runs natively on Windows (Batch/PowerShell), macOS, and Linux (Bash). No Python, Node.js, or external dependencies required.
- **Graphical Folder Selection**: Uses a native popup to easily select the target directory (WinForms on Windows, AppleScript on macOS, Zenity on Linux).
- **Smart Chunking**: Automatically splits the extracted media into folders of a custom size (e.g., 10 GB) so you can easily transfer them via USB flash drives. Or disable chunking to put everything into one folder.
- **Year & Type Sorting**: Optionally sort all extracted photos and videos into subfolders based on the year they were created and their media type (e.g., `2015/Photos`, `2015/Videos`).
- **Duplicate Protection**: Automatically renames duplicate files (e.g., `IMG_001.jpg` -> `IMG_001_1.jpg`) instead of overwriting them.
- **Live Progress & ETA**: Displays a custom character-based progress bar and estimated time of completion directly in the terminal.
- **Safe Cleanup**: Asks for explicit user confirmation before permanently deleting the junk files left behind.

## 💻 Supported Systems
- **Windows**: 7, 8, 8.1, 10, 11 (Runs via `MediaExtractor.bat`)
- **macOS**: All modern versions (Runs via `MediaExtractor.sh`)
- **Linux**: Ubuntu, Mint, Debian, Fedora, Arch, etc. (Runs via `MediaExtractor.sh`)

## 📸 Supported Formats
- **Photos**: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.tiff`, `.raw`, `.webp`, `.heic`
- **Videos**: `.mp4`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.flv`, `.webm`, `.m4v`, `.3gp`

## 🛠 How to Use

### On Windows 🪟
1. Download the `MediaExtractor.bat` file.
2. Double-click it to run.

### On macOS 🍎 / Linux 🐧
1. Download the `MediaExtractor.sh` file.
2. Open your Terminal and navigate to where the file is downloaded.
3. Make it executable: `chmod +x MediaExtractor.sh`
4. Run it: `./MediaExtractor.sh` (or `bash MediaExtractor.sh`)

### Execution Flow
1. The terminal will ask if you want to COPY files instead of moving them. Enter `Y` to copy (keep original files) or `N` to move.
2. It will ask if you want to split files into chunks (e.g., 10GB for flash drives). Enter `Y` or `N`.
3. It will then ask if you want to sort files into subfolders by year. Enter `Y` or `N`.
4. A graphical folder selection window will appear (or a terminal prompt on some Linux setups). Choose the folder you want to clean.
5. The script will scan the folder and move/copy all media files to a new folder named `Saved_Media_[YourFolderName]` located next to the original folder.
6. Once the transfer is complete (if you chose to move files), the script will ask if you want to permanently delete the original folder (which now only contains junk). Type `Y` to delete, or close the terminal/press Enter to keep it.

## 🛡 Security & Offline Use
Because these scripts utilize pure OS-native APIs, they do not connect to the internet. This makes them completely safe to use on old, offline, or heavily infected machines without risking network-based malware transmission. They effectively act as filters, extracting only safe media extensions and leaving executable viruses (`.exe`, `.vbs`, `.sh`) behind to be deleted.
