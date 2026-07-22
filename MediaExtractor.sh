#!/usr/bin/env bash
# Media Extractor for macOS and Linux

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
read -p "Do you want to COPY files instead of moving them? (Y/N): " copyChoice
isCopy=false
if [[ "$copyChoice" =~ ^[Yy] ]]; then
    isCopy=true
    echo -e "-> ${GREEN}Files will be COPIED. Original files will remain untouched.${NC}"
else
    echo -e "-> ${GREEN}Files will be MOVED. Original files will be removed from the source folder.${NC}"
fi

# Ask for splitting
read -p "Do you want to split the saved files into parts by size? (Y/N): " splitChoice
isSplitting=false
maxSize=9223372036854775807 # huge number

if [[ "$splitChoice" =~ ^[Yy] ]]; then
    read -p "Enter the maximum size for each part in Gigabytes (e.g., 5, 10, 16) or 0 for no splitting: " sizeInput
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
read -p "Do you want to sort files into subfolders by Year? (Y/N): " sortChoice
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
saveBaseDir="$parentDir/Saved_Media_$folderName"

currentPart=1
currentSize=0

echo -e "${CYAN}Scanning for photos and videos in $targetDir ...${NC}"

# Find media files
mapfile -d $'\0' filesToMove < <(find "$targetDir" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
    -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.raw" -o -iname "*.webp" -o \
    -iname "*.heic" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o \
    -iname "*.mov" -o -iname "*.wmv" -o -iname "*.flv" -o -iname "*.webm" -o \
    -iname "*.m4v" -o -iname "*.3gp" \) -print0 2>/dev/null)

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
        jpg|jpeg|png|gif|bmp|tiff|raw|webp|heic) echo "Photos" ;;
        mp4|avi|mkv|mov|wmv|flv|webm|m4v|3gp) echo "Videos" ;;
        *) echo "Other" ;;
    esac
}

totalBytes=0
for f in "${filesToMove[@]}"; do
    size=$(get_size "$f")
    totalBytes=$((totalBytes + size))
done

totalMB=$(awk "BEGIN {printf \"%.2f\", $totalBytes/1048576}")
echo -e "${GREEN}Photos and videos found: $totalFiles${NC}"
echo -e "${GREEN}Total size: $totalMB MB${NC}"
spinnerChars=('|' '/' '-' '\')
spinnerIdx=0
lastProcessed=()

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
    
    # Duplicate protection
    counter=1
    while [ -e "$destPath" ]; then
        destPath="$partDir/${fileName}_${counter}${extension}"
        counter=$((counter + 1))
    done

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
    read -p "Delete junk files PERMANENTLY? (Y/N): " response

    if [[ "$response" =~ ^[Yy] ]]; then
        echo -e "${CYAN}Deleting junk...${NC}"
        rm -rf "$targetDir"
        echo -e "${GREEN}Junk successfully deleted!${NC}"
    else
        echo -e "${YELLOW}Deletion cancelled. The old folder has been kept.${NC}"
    fi
fi
