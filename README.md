# Local Media Extractor

A fast, lightweight, and interactive Windows Batch/PowerShell hybrid script designed to extract photos and videos from messy, junk-filled folders on old computers. It works entirely offline and uses native Windows components for maximum speed and compatibility.

## 🚀 Features
- **Zero Installation**: Runs natively on Windows 7, 8, 10, and 11. No Python, Node.js, or external dependencies required.
- **Graphical Folder Selection**: Uses a native Windows popup to easily select the target directory.
- **Smart Chunking**: Automatically splits the extracted media into folders of a custom size (e.g., 10 GB) so you can easily transfer them via USB flash drives. Or disable chunking to put everything into one folder.
- **Year-Based Sorting**: Optionally sort all extracted photos and videos into subfolders based on the year they were created (e.g., `2015`, `2021`).
- **Duplicate Protection**: Automatically renames duplicate files (e.g., `IMG_001.jpg` -> `IMG_001_1.jpg`) instead of overwriting them.
- **Live Progress & ETA**: Displays a custom character-based progress bar and estimated time of completion directly in the terminal.
- **Safe Cleanup**: Asks for explicit user confirmation before permanently deleting the junk files left behind.

## 📸 Supported Formats
- **Photos**: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.tiff`, `.raw`, `.webp`, `.heic`
- **Videos**: `.mp4`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.flv`, `.webm`, `.m4v`

## 🛠 How to Use
1. Download the `MediaExtractor.bat` file.
2. Double-click it to run.
3. The terminal will ask if you want to split files into chunks (e.g., 10GB for flash drives). Enter `Y` or `N`.
4. It will then ask if you want to sort files into subfolders by year. Enter `Y` or `N`.
5. A standard Windows folder selection window will appear. Choose the folder you want to clean.
6. The script will scan the folder and move all media files to a new folder named `Saved_Media_[YourFolderName]` located next to the original folder.
7. Once the transfer is complete, the script will ask if you want to permanently delete the original folder (which now only contains junk). Type `Y` to delete, or close the window to keep it.

## 🛡 Security & Offline Use
Because this script utilizes pure Batch and PowerShell APIs, it does not connect to the internet. This makes it completely safe to use on old, offline, or heavily infected Windows machines without risking network-based malware transmission. It effectively acts as a filter, extracting only safe media extensions and leaving executable viruses (`.exe`, `.vbs`, `.bat`) behind to be deleted.
