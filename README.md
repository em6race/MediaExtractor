# Local Media Extractor

*🌍 [Українська версія нижче / Ukrainian version below](#-українська-версія-ukrainian)*

A fast, lightweight, and interactive script designed to extract photos and videos from messy, junk-filled folders on old computers. It works entirely offline and uses native OS components for maximum speed and compatibility.

## 🚀 Features
- **Zero Installation**: Runs strictly on OS-native commands (Batch/PowerShell for Windows, Bash for Mac/Linux).
- **Chunk Splitting**: Can split the extracted media into separate numbered folders (e.g., 10GB chunks) so they can be easily moved onto small external flash drives.
- **Chronological Sorting**: Option to sort media automatically into year-based subfolders by analyzing file modification dates.
- **Type Separation**: Separates photos and videos into different folders automatically.
- **Smart Duplicate Prevention**: Compares files by exact byte size. If a perfect duplicate is found, it skips it to save space. If names match but sizes differ, it safely renames the file to keep both.
- **Safe Mode**: Can copy files instead of moving them, leaving the original folder completely untouched.
- **Live Progress & ETA**: Displays a custom character-based progress bar and estimated time of completion directly in the terminal.
- **Safe Cleanup**: Asks for explicit user confirmation before permanently deleting the junk files left behind.

## 💻 Supported Systems
- **Windows**: 7, 8, 8.1, 10, 11 (Runs via `MediaExtractor.bat`)
- **macOS**: All modern versions (Runs via `MediaExtractor.sh`)
- **Linux**: Ubuntu, Mint, Debian, Fedora, Arch, etc. (Runs via `MediaExtractor.sh`)

## 📸 Supported Formats
- **Photos**: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.tiff`, `.tif`, `.raw`, `.cr2`, `.nef`, `.orf`, `.sr2`, `.dng`, `.psd`, `.webp`, `.heic`, `.avif`, `.jp2`, `.ico`
- **Videos**: `.mp4`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.flv`, `.webm`, `.m4v`, `.3gp`, `.mpg`, `.mpeg`, `.m2ts`, `.mts`, `.ts`, `.vob`, `.rm`, `.rmvb`, `.asf`, `.divx`

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
5. The script will scan the folder and move/copy all media files to a new folder named `Saved_Media_[YourFolderName]_[Timestamp]` located next to the original folder.
6. Once the transfer is complete (if you chose to move files), the script will ask if you want to permanently delete the original folder (which now only contains junk). Type `Y` to delete, or close the terminal/press Enter to keep it.

## 🛡 Security & Offline Use
Because these scripts utilize pure OS-native APIs, they do not connect to the internet. This makes them completely safe to use on old, offline, or heavily infected machines without risking network-based malware transmission. They effectively act as filters, extracting only safe media extensions and leaving executable viruses (`.exe`, `.vbs`, `.sh`) behind to be deleted.

---

# 🇺🇦 Українська версія (Ukrainian)

Швидкий, легкий та інтерактивний скрипт, створений для вилучення фотографій та відео з брудних, заповнених сміттям папок на старих комп'ютерах. Працює повністю автономно (без інтернету) та використовує вбудовані компоненти ОС для максимальної швидкості та сумісності.

## 🚀 Можливості
- **Жодних встановлень**: Працює виключно на вбудованих командах ОС (Batch/PowerShell для Windows, Bash для Mac/Linux).
- **Розділення на частини**: Може розбивати витягнуті медіа на окремі пронумеровані папки (наприклад, по 10 ГБ), щоб їх було легко перенести на невеликі флешки.
- **Хронологічне сортування**: Опція автоматичного сортування медіа у підпапки за роками на основі дати створення файлів.
- **Розділення за типом**: Автоматично розділяє фотографії та відео у різні папки.
- **Розумний захист від дублікатів**: Порівнює файли за точним розміром у байтах. Якщо знайдено ідеальну копію, скрипт пропускає її для економії місця. Якщо назви збігаються, але розміри різні, він безпечно перейменовує файл, щоб зберегти обидва.
- **Безпечний режим**: Може копіювати файли замість їхнього переміщення, залишаючи оригінальну папку абсолютно недоторканою.
- **Прогрес-бар у реальному часі**: Відображає динамічний прогрес-бар та орієнтовний час завершення (ETA) прямо у терміналі.
- **Безпечне очищення**: Запитує чітке підтвердження користувача перед остаточним видаленням сміттєвих файлів, що залишилися.

## 💻 Підтримувані системи
- **Windows**: 7, 8, 8.1, 10, 11 (Працює через `MediaExtractor.bat`)
- **macOS**: Всі сучасні версії (Працює через `MediaExtractor.sh`)
- **Linux**: Ubuntu, Mint, Debian, Fedora, Arch та ін. (Працює через `MediaExtractor.sh`)

## 📸 Підтримувані формати
- **Фото**: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.tiff`, `.tif`, `.raw`, `.cr2`, `.nef`, `.orf`, `.sr2`, `.dng`, `.psd`, `.webp`, `.heic`, `.avif`, `.jp2`, `.ico`
- **Відео**: `.mp4`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.flv`, `.webm`, `.m4v`, `.3gp`, `.mpg`, `.mpeg`, `.m2ts`, `.mts`, `.ts`, `.vob`, `.rm`, `.rmvb`, `.asf`, `.divx`

## 🛠 Як користуватися

### На Windows 🪟
1. Завантажте файл `MediaExtractor.bat`.
2. Двічі клацніть по ньому, щоб запустити.

### На macOS 🍎 / Linux 🐧
1. Завантажте файл `MediaExtractor.sh`.
2. Відкрийте Термінал (Terminal) і перейдіть у папку, де завантажено файл.
3. Зробіть його виконуваним: `chmod +x MediaExtractor.sh`
4. Запустіть його: `./MediaExtractor.sh` (або `bash MediaExtractor.sh`)

### Процес роботи
1. Термінал запитає, чи хочете ви СКОПІЮВАТИ файли замість їхнього переміщення. Введіть `Y`, щоб скопіювати (зберегти оригінали), або `N`, щоб перемістити.
2. Далі він запитає, чи хочете ви розділити файли на частини (наприклад, по 10 ГБ для флешок). Введіть `Y` або `N`.
3. Потім він запитає, чи хочете ви розсортувати файли у підпапки за роками. Введіть `Y` або `N`.
4. З'явиться графічне вікно вибору папки (або запит у терміналі на деяких Linux-системах). Виберіть папку, яку хочете очистити.
5. Скрипт просканує папку та перемістить/скопіює всі медіафайли у нову папку з назвою `Saved_Media_[ВашаПапка]_[ТочнийЧас]`, розташовану поруч із оригінальною папкою.
6. Коли перенесення завершиться (якщо ви обрали переміщення файлів), скрипт запитає, чи хочете ви назавжди видалити оригінальну папку (яка тепер містить лише сміття). Введіть `Y`, щоб видалити, або просто закрийте термінал/натисніть Enter, щоб залишити її.

## 🛡 Безпека та використання без інтернету
Оскільки ці скрипти використовують виключно вбудовані API операційної системи, вони взагалі не підключаються до інтернету. Це робить їх абсолютно безпечними для використання на старих, відключених від мережі або сильно заражених вірусами машинах без ризику передачі шкідливого ПЗ по мережі. Вони фактично працюють як фільтри, витягуючи лише безпечні медіа-формати та залишаючи виконувані віруси (`.exe`, `.vbs`, `.sh`) позаду для подальшого видалення.
