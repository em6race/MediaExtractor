#!/usr/bin/env bash
# Media Extractor for macOS and Linux
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}   Media Extractor Script (macOS / Linux)                 ${NC}"
echo -e "${CYAN}   With logs, chunking, year sorting, and media type      ${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo ""

# Ask for copy vs move
echo -ne "${YELLOW}[1/4] Do you want to COPY files instead of moving them? (Y/N, default N): ${NC}"
read copyChoice
isCopy=false
if [[ "$copyChoice" =~ ^[Yy] ]]; then
    isCopy=true
    echo -e "-> ${GREEN}Files will be COPIED. Original files will remain untouched.${NC}"
else
    echo -e "-> ${GREEN}Files will be MOVED. Original files will be removed from the source folder.${NC}"
fi

# Ask for splitting
echo -ne "${YELLOW}[2/4] Do you want to split the saved files into parts by size? (Y/N, default N): ${NC}"
read splitChoice
isSplitting=false
maxSize=9223372036854775807 # huge number

if [[ "$splitChoice" =~ ^[Yy] ]]; then
    echo -ne "${YELLOW}  > Enter the maximum size for each part in GB (e.g., 5, 10, 16): ${NC}"
    read sizeInput
    if [[ "$sizeInput" =~ ^[0-9]+$ ]] && [ "$sizeInput" -gt 0 ]; then
        maxSize=$((sizeInput * 1024 * 1024 * 1024))
        isSplitting=true
        echo -e "-> ${GREEN}Files will be split into parts of up to $sizeInput GB.${NC}"
    else
        echo -e "-> ${GREEN}Files will NOT be split.${NC}"
    fi
else
    echo -e "-> ${GREEN}Files will NOT be split.${NC}"
fi

# Ask for sorting
echo -ne "${YELLOW}[3/4] Do you want to sort files into subfolders by Year? (Y/N, default N): ${NC}"
read sortChoice
isSorting=false
if [[ "$sortChoice" =~ ^[Yy] ]]; then
    isSorting=true
    echo -e "-> ${GREEN}Files will be sorted by Year.${NC}"
else
    echo -e "-> ${GREEN}Files will NOT be sorted by Year.${NC}"
fi
echo ""

# Folder selection
targetDir=""
echo -e "${YELLOW}[4/4] Please select the folder with old files to clean${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Try osascript for macOS
    targetDir=$(osascript -e 'set folderPath to choose folder with prompt "Select the folder with old files to clean"' -e 'POSIX path of folderPath' 2>/dev/null)
elif command -v zenity &> /dev/null; then
    # Try zenity for Linux
    targetDir=$(zenity --file-selection --directory --title="Select the folder with old files to clean" 2>/dev/null)
fi

if [ -z "$targetDir" ]; then
    echo -e "${YELLOW}Graphical folder selection not available or cancelled.${NC}"
    read -p "Please enter or drag-and-drop the folder path to clean: " targetDir
fi

# Clean up path
targetDir=$(echo "$targetDir" | sed "s/^'//;s/'$//") # remove quotes if dragged

if [ ! -d "$targetDir" ]; then
    echo -e "${RED}Error: Folder does not exist: $targetDir${NC}"
    exit 1
fi

folderName=$(basename "$targetDir")
parentDir=$(dirname "$targetDir")
timestamp=$(date +"%Y%m%d_%H%M%S")
saveBaseDir="$parentDir/Saved_Media_${folderName}_${timestamp}"

currentPart=1
currentSize=0

echo -e "${CYAN}Scanning for photos and videos in $targetDir ...${NC}"

# Find media files
mapfile -d $'\0' filesToMove < <(find "$targetDir" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
    -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.tif" -o -iname "*.raw" -o \
    -iname "*.cr2" -o -iname "*.nef" -o -iname "*.orf" -o -iname "*.sr2" -o \
    -iname "*.dng" -o -iname "*.psd" -o -iname "*.webp" -o -iname "*.heic" -o \
    -iname "*.avif" -o -iname "*.jp2" -o -iname "*.ico" -o \
    -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mov" -o \
    -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o -iname "*.m4v" -o \
    -iname "*.3gp" -o -iname "*.mpg" -o -iname "*.mpeg" -o -iname "*.m2ts" -o \
    -iname "*.mts" -o -iname "*.ts" -o -iname "*.vob" -o -iname "*.rm" -o \
    -iname "*.rmvb" -o -iname "*.asf" -o -iname "*.divx" \) -print0 2>/dev/null)

totalFiles=${#filesToMove[@]}
if [ "$totalFiles" -eq 0 ]; then
    echo -e "${YELLOW}No media files found.${NC}"
    exit 0
fi

# Helper functions for macOS vs Linux stat
if [[ "$OSTYPE" == "darwin"* ]]; then
    get_size() { stat -f "%z" "$1" 2>/dev/null || echo 0; }
    get_year() { stat -f "%Sm" -t "%Y" "$1" 2>/dev/null || echo "Unknown_Year"; }
else
    get_size() { stat -c "%s" "$1" 2>/dev/null || echo 0; }
    get_year() { date -d "$(stat -c "%y" "$1" 2>/dev/null)" +"%Y" 2>/dev/null || echo "Unknown_Year"; }
fi

# Determine type based on extension
get_type() {
    local ext="${1##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    case "$ext" in
        jpg|jpeg|png|gif|bmp|tiff|tif|raw|cr2|nef|orf|sr2|dng|psd|webp|heic|avif|jp2|ico) echo "Photos" ;;
        mp4|avi|mkv|mov|wmv|flv|webm|m4v|3gp|mpg|mpeg|m2ts|mts|ts|vob|rm|rmvb|asf|divx) echo "Videos" ;;
        *) echo "Other" ;;
    esac
}

# 7zz command path (set by pre-download block below)
PORTABLE_7ZZ_PATH=""

get_7zz() {
    # Return system 7z if available, otherwise the pre-downloaded portable
    if command -v 7zz >/dev/null 2>&1; then
        echo "7zz"; return
    fi
    if command -v 7z >/dev/null 2>&1; then
        echo "7z"; return
    fi
    if [ -n "$PORTABLE_7ZZ_PATH" ] && [ -f "$PORTABLE_7ZZ_PATH" ]; then
        echo "$PORTABLE_7ZZ_PATH"
    fi
}

totalBytes=0
for f in "${filesToMove[@]}"; do
    size=$(get_size "$f")
    totalBytes=$((totalBytes + size))
done

totalMB=$(awk "BEGIN {printf \"%.2f\", $totalBytes/1048576}")
echo -e "${GREEN}Photos and videos found: $totalFiles${NC}"
echo -e "${GREEN}Total size: $totalMB MB${NC}"

# --- Pre-download archiver if needed ---
if [ "$processArchives" = true ]; then
    if ! command -v 7zz >/dev/null 2>&1 && ! command -v 7z >/dev/null 2>&1; then
        toolsDir="$saveBaseDir/.temp_tools"
        mkdir -p "$toolsDir"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            binaryName="7zz-mac"
        else
            binaryName="7zz-linux"
        fi
        PORTABLE_7ZZ_PATH="$toolsDir/$binaryName"
        
        if [ ! -f "$PORTABLE_7ZZ_PATH" ]; then
            # First check local tools/ folder (next to the script, e.g. full repo download)
            localTool="$SCRIPT_DIR/tools/$binaryName"
            if [ -f "$localTool" ]; then
                cp "$localTool" "$PORTABLE_7ZZ_PATH"
                chmod +x "$PORTABLE_7ZZ_PATH" 2>/dev/null
                echo -e "${CYAN}  Found local tools/$binaryName, using it.${NC}"
            else
                echo -e ""
                echo -e "${YELLOW}  No archiver found on this system.${NC}"
                echo -e "${YELLOW}  Downloading portable $binaryName from repo...${NC}"
                url="https://raw.githubusercontent.com/em6race/MediaExtractor/main/tools/$binaryName"
                
                if command -v curl >/dev/null 2>&1; then
                    curl -# -o "$PORTABLE_7ZZ_PATH" "$url"
                    dlExit=$?
                elif command -v wget >/dev/null 2>&1; then
                    wget --show-progress -q -O "$PORTABLE_7ZZ_PATH" "$url"
                    dlExit=$?
                else
                    echo -e "${RED}  No curl or wget found. RAR/7z archives will be skipped.${NC}"
                    dlExit=1
                fi
                
                if [ $dlExit -eq 0 ]; then
                    chmod +x "$PORTABLE_7ZZ_PATH" 2>/dev/null
                    echo -e "${GREEN}  Download complete! Will be removed after processing.${NC}"
                else
                    echo -e "${RED}  Download failed. RAR/7z archives will be skipped.${NC}"
                    PORTABLE_7ZZ_PATH=""
                    rm -f "$PORTABLE_7ZZ_PATH" 2>/dev/null
                fi
            fi
        else
            echo -e "${CYAN}  Using cached portable $binaryName.${NC}"
        fi
        echo ""
    fi
fi
# --- End pre-download ---

spinnerChars=('|' '/' '-' '\')
spinnerIdx=0
lastProcessed=()
lastUiSecond=$SECONDS
lastUiBytes=0

# Setup empty lines for UI
for i in {1..12}; do echo ""; done

movedBytes=0
startTime=$(date +%s)

for file in "${filesToMove[@]}"; do
    fileSize=$(get_size "$file")

    # Splitting logic
    if [ "$isSplitting" = true ] && [ "$currentSize" -gt 0 ] && [ $((currentSize + fileSize)) -gt "$maxSize" ]; then
        currentPart=$((currentPart + 1))
        currentSize=0
    fi

    if [ "$isSplitting" = true ]; then
        baseDestDir="$saveBaseDir/Part_$currentPart"
    else
        baseDestDir="$saveBaseDir/All_Media"
    fi

    mediaType=$(get_type "$file")

    # Sorting logic
    if [ "$isSorting" = true ]; then
        year=$(get_year "$file")
        if ! [[ "$year" =~ ^[0-9]{4}$ ]]; then year="Unknown_Year"; fi
        partDir="$baseDestDir/$year/$mediaType"
    else
        partDir="$baseDestDir/$mediaType"
    fi

    mkdir -p "$partDir"

    baseName=$(basename "$file")
    fileName="${baseName%.*}"
    extension="${baseName##*.}"
    if [ "$fileName" = "$extension" ]; then extension=""; else extension=".$extension"; fi

    destPath="$partDir/$baseName"
    
    # Duplicate protection with size check
    skipFile=false
    counter=1
    while [ -e "$destPath" ]; do
        existingSize=$(get_size "$destPath")
        if [ "$existingSize" -eq "$fileSize" ]; then
            skipFile=true
            break
        fi
        destPath="$partDir/${fileName}_${counter}${extension}"
        counter=$((counter + 1))
    done

    if [ "$skipFile" = true ]; then
        movedBytes=$((movedBytes + fileSize))
        if [ "$isCopy" = false ]; then
            rm -f "$file" 2>/dev/null
        fi
        continue
    fi

    if [ "$isCopy" = true ]; then
        cp "$file" "$destPath" 2>/dev/null
    else
        mv "$file" "$destPath" 2>/dev/null
    fi
    
    movedBytes=$((movedBytes + fileSize))
    currentSize=$((currentSize + fileSize))

    # Calculate ETA and Progress
    currentTime=$(date +%s)
    elapsed=$((currentTime - startTime))
    
    if [ "$totalBytes" -gt 0 ]; then
        percent=$((movedBytes * 100 / totalBytes))
    else
        percent=100
    fi
    [ "$percent" -gt 100 ] && percent=100

    if [ "$elapsed" -gt 0 ] && [ "$movedBytes" -gt 0 ]; then
        speed=$((movedBytes / elapsed))
        if [ "$speed" -gt 0 ]; then
            etaSeconds=$(((totalBytes - movedBytes) / speed))
            if [ "$etaSeconds" -lt 0 ]; then etaSeconds=0; fi
            h=$((etaSeconds / 3600))
            m=$(((etaSeconds % 3600) / 60))
            s=$((etaSeconds % 60))
            if [ "$h" -gt 0 ]; then
                etaStr=$(printf "%02d:%02d:%02d" $h $m $s)
            else
                etaStr=$(printf "%02d:%02d" $m $s)
            fi
        else
            etaStr="--:--"
        fi
    else
        etaStr="--:--"
    fi

    filled=$((percent / 5))
    empty=$((20 - filled))
    bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}#"; done
    for ((i=0; i<empty; i++)); do bar="${bar}-"; done

    # Color logic
    if [ "$percent" -lt 34 ]; then
        barColor="${RED}"
    elif [ "$percent" -lt 67 ]; then
        barColor="${YELLOW}"
    else
        barColor="${GREEN}"
    fi

    spinChar="${spinnerChars[$((spinnerIdx % 4))]}"
    spinnerIdx=$((spinnerIdx + 1))
    
    # Add to array
    lastProcessed+=("$baseName")
    if [ ${#lastProcessed[@]} -gt 7 ]; then
        lastProcessed=("${lastProcessed[@]:1}")
    fi
    
    # UI Drawing
    bytesSinceLastUi=$((movedBytes - lastUiBytes))
    if [ "$bytesSinceLastUi" -gt 5242880 ] || [ "$SECONDS" -ne "$lastUiSecond" ] || [ "$movedBytes" -eq "$totalBytes" ]; then
        lastUiSecond=$SECONDS
        lastUiBytes=$movedBytes

        # Move cursor up 12 lines
        printf "\033[12A"
    
    printf "\033[K${CYAN}Starting transfer...${NC}\n"
    printf "\033[K${CYAN}--------------------------------------------------------${NC}\n"
    printf "\033[K${CYAN}[${spinChar}] ${percent}%% [${barColor}${bar}${CYAN}] ETA: ${etaStr} | Total: ${totalFiles}${NC}\n"
    printf "\033[K${CYAN}--------------------------------------------------------${NC}\n"
    printf "\033[K${CYAN}Recently processed (Last 7):${NC}\n"
    
    for i in {0..6}; do
        if [ "$i" -lt "${#lastProcessed[@]}" ]; then
            name="${lastProcessed[$i]}"
            if [ ${#name} -gt 50 ]; then name="${name:0:47}..."; fi
            printf "\033[K  ${GREEN}> %-50s${NC}\n" "$name"
        else
            printf "\033[K\n"
        fi
    done
    fi
done

echo ""
echo -e "${CYAN}--------------------------------------------------------${NC}"
echo -e "${GREEN}Transfer completed!${NC}"
echo -e "${YELLOW}All your files have been saved to: $saveBaseDir${NC}"
if [ "$isSplitting" = true ] && [ "$currentPart" -gt 1 ]; then
    echo -e "${MAGENTA}Files were automatically split into $currentPart part(s).${NC}"
fi

if [ "$isCopy" = false ]; then
    echo -e "${CYAN}--------------------------------------------------------${NC}"
    echo -e "${RED}WARNING: Only junk files remain in the old folder ($targetDir).${NC}"
    echo -ne "${YELLOW}[5/5] Do you want to permanently delete the original folder (containing only junk)? (Y/N, default N): ${NC}"
    read response

    if [[ "$response" =~ ^[Yy] ]]; then
        echo -e "${CYAN}Deleting junk...${NC}"
        rm -rf "$targetDir"
        echo -e "${GREEN}Junk successfully deleted!${NC}"
    else
        echo -e "${YELLOW}Deletion cancelled. The old folder has been kept.${NC}"
    fi
fi
