#!/usr/bin/env bash

# resize_jpg.sh
# Cross-platform JPG resize script for macOS and Linux
# Requires ImageMagick (`convert` or `magick`)
# Usage:
#   ./resize_jpg.sh input.jpg 50
#   -> creates input_resized.jpg at 50% of original size

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input.jpg> <percentage>"
    echo "Example: $0 photo.jpg 50"
    exit 1
fi

INPUT="$1"
PERCENT="$2"

# Validate input file
if [ ! -f "$INPUT" ]; then
    echo "Error: File '$INPUT' not found."
    exit 1
fi

# Validate percentage (positive integer)
if ! [[ "$PERCENT" =~ ^[0-9]+$ ]] || [ "$PERCENT" -le 0 ]; then
    echo "Error: Percentage must be a positive integer."
    exit 1
fi

# Check extension
EXTENSION="${INPUT##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

if [[ "$EXTENSION_LOWER" != "jpg" && "$EXTENSION_LOWER" != "jpeg" ]]; then
    echo "Error: Input file must be a JPG/JPEG image."
    exit 1
fi

# Determine ImageMagick command
if command -v magick >/dev/null 2>&1; then
    IM_CMD=(magick)
elif command -v convert >/dev/null 2>&1; then
    IM_CMD=(convert)
else
    echo "Error: ImageMagick is not installed."
    echo "Install it with:"
    echo "  macOS: brew install imagemagick"
    echo "  Linux: sudo apt install imagemagick"
    exit 1
fi

# Output filename
BASENAME="${INPUT%.*}"
OUTPUT="${BASENAME}_resized.jpg"

# Resize image
"${IM_CMD[@]}" "$INPUT" -resize "${PERCENT}%" "$OUTPUT"

echo "Resized image created: $OUTPUT"
