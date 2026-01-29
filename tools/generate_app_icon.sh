#!/bin/bash
# Generate macOS app icons from source image
# Usage: ./tools/generate_app_icon.sh [source_image]

set -e

SOURCE="${1:-assets/images/character_2.png}"
ICONSET="macos/Runner/Assets.xcassets/AppIcon.appiconset"
TEMP_DIR=$(mktemp -d)

echo "=== Generating App Icons ==="
echo "Source: $SOURCE"

if [ ! -f "$SOURCE" ]; then
    echo "Error: Source image not found: $SOURCE"
    exit 1
fi

# Get image dimensions
WIDTH=$(sips -g pixelWidth "$SOURCE" | tail -1 | awk '{print $2}')
HEIGHT=$(sips -g pixelHeight "$SOURCE" | tail -1 | awk '{print $2}')
echo "Original size: ${WIDTH}x${HEIGHT}"

# Determine the square size (use larger dimension)
if [ "$WIDTH" -gt "$HEIGHT" ]; then
    SQUARE_SIZE=$WIDTH
else
    SQUARE_SIZE=$HEIGHT
fi

echo "Creating square image: ${SQUARE_SIZE}x${SQUARE_SIZE}"

# Create a square image by padding
cp "$SOURCE" "$TEMP_DIR/source.png"
sips -p $SQUARE_SIZE $SQUARE_SIZE "$TEMP_DIR/source.png" --out "$TEMP_DIR/square.png" > /dev/null

# Generate all required sizes
SIZES=(16 32 64 128 256 512 1024)

for size in "${SIZES[@]}"; do
    OUTPUT="$ICONSET/app_icon_${size}.png"
    sips -z $size $size "$TEMP_DIR/square.png" --out "$OUTPUT" > /dev/null
    echo "  Created: app_icon_${size}.png"
done

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "=== Done! ==="
echo "App icons updated in: $ICONSET"
echo ""
echo "Rebuild the app to see the new icon:"
echo "  flutter build macos --release"
