#!/bin/bash

# Script to organize photos and videos by date and location
# Works on Linux and macOS
# Requires: exiftool, curl, jq

set -e

# Load configuration
source ./config.sh

# Default options
verbose=false

# Parse options
while getopts "v" opt; do
    case $opt in
        v) verbose=true ;;
        *) echo "Usage: $0 [-v] <SOURCE>"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -ne 1 ]; then
    echo "Usage: $0 [-v] <SOURCE>"
    exit 1
fi

SOURCE="$1"
OUTPUT_DIR="${SOURCE}_Organized"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to get file datetime
get_datetime() {
    local file="$1"
    local dt
    dt=$(exiftool -b -DateTimeOriginal "$file" 2>/dev/null)
    if [ -n "$dt" ]; then
        echo "$dt"
        return
    fi
    # Fallback to file modification time
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f "%Sm" -t "%Y:%m:%d %H:%M:%S" "$file"
    else
        stat -c "%y" "$file" | cut -d. -f1 | sed 's/-/:/g' | sed 's/ /:/g'
    fi
}

# Function to get city and country from lat/lon
get_location() {
    local lat="$1"
    local lon="$2"
    local response
    response=$(curl -s -A "organize_foto.sh/1.0" "$NOMINATIM_BASE_URL/reverse?format=json&lat=$lat&lon=$lon")
    local city country
    city=$(echo "$response" | jq -r '.address.city // .address.town // .address.village // "Unknown"')
    country=$(echo "$response" | jq -r '.address.country // "Unknown"')
    echo "${city}_${country}"
}

# Find all image and video files
files=$(find "$SOURCE" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.mkv" -o -iname "*.wmv" \))
total_files=$(echo "$files" | wc -l)
counter=0
temp_file=$(mktemp)

while read -r file; do
    counter=$((counter + 1))
    if [ "$verbose" = true ]; then
        echo "Processing $file"
    else
        percent=$((counter * 100 / total_files))
        echo -ne "Processing $counter/$total_files ($percent%): $(basename "$file")\r"
    fi

    # Check for duplicate MD5
    md5=$(md5sum "$file" | cut -d' ' -f1)
    if grep -q "$md5" "$temp_file"; then
        if [ "$verbose" = true ]; then
            echo "Duplicate file (same MD5), skipping"
        fi
        continue
    fi
    echo "$md5" >> "$temp_file"

    # Get datetime
    datetime=$(get_datetime "$file")
    if [ -z "$datetime" ]; then
        if [ "$verbose" = true ]; then
            echo "No date found for $file, skipping"
        fi
        continue
    fi

    if [ "$verbose" = true ]; then
        echo "DateTime: $datetime"
    fi

    # Parse datetime (format: YYYY:MM:DD HH:MM:SS)
    date_part=$(echo "$datetime" | awk '{print $1}')
    time_part=$(echo "$datetime" | awk '{print $2}')
    year=$(echo "$date_part" | cut -d: -f1)
    month=$(echo "$date_part" | cut -d: -f2)
    day=$(echo "$date_part" | cut -d: -f3)
    hour=$(echo "$time_part" | cut -d: -f1)
    minute=$(echo "$time_part" | cut -d: -f2)

    timestamp="${year}${month}${day}_${hour}${minute}"

    # Get GPS
    lat=$(exiftool -b -GPSLatitude "$file" 2>/dev/null)
    lat_ref=$(exiftool -b -GPSLatitudeRef "$file" 2>/dev/null)
    lon=$(exiftool -b -GPSLongitude "$file" 2>/dev/null)
    lon_ref=$(exiftool -b -GPSLongitudeRef "$file" 2>/dev/null)

    location="Unknown_Unknown"
    if [ -n "$lat" ] && [ -n "$lon" ]; then
        # Convert to decimal
        lat_dec=$(echo "$lat" | awk -F' ' '{print $1 + $2/60 + $3/3600}')
        lon_dec=$(echo "$lon" | awk -F' ' '{print $1 + $2/60 + $3/3600}')
        if [ "$lat_ref" = "S" ]; then lat_dec="-$lat_dec"; fi
        if [ "$lon_ref" = "W" ]; then lon_dec="-$lon_dec"; fi

        location=$(get_location "$lat_dec" "$lon_dec")
        # Sleep to respect rate limit
        sleep 1
    fi

    if [ "$verbose" = true ]; then
        echo "GPS: $lat $lat_ref, $lon $lon_ref -> Location: $location_clean"
    fi

    # Sanitize location for filename
    location_clean=$(echo "$location" | tr ' ' '_' | sed 's/[^a-zA-Z0-9_]//g')

    # Get extension
    ext=$(basename "$file" | awk -F. '{print tolower($NF)}')

    # Create directory
    mkdir -p "$OUTPUT_DIR/$year/$month"

    # Create hard link
    target="$OUTPUT_DIR/$year/$month/${timestamp}_${location_clean}.$ext"
    if [ -e "$target" ]; then
        # Handle duplicates
        dcounter=1
        while [ -e "$OUTPUT_DIR/$year/$month/${timestamp}_${location_clean}_$dcounter.$ext" ]; do
            dcounter=$((dcounter + 1))
        done
        target="$OUTPUT_DIR/$year/$month/${timestamp}_${location_clean}_$dcounter.$ext"
    fi
    ln "$file" "$target"
    if [ "$verbose" = true ]; then
        echo "Linked to $target"
    fi
done < <(echo "$files")

rm "$temp_file"

echo ""
echo "Done. Found $total_files files."