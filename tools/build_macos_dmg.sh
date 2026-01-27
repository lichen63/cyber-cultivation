#!/bin/bash
# Script to build macOS DMG
# Usage: ./tools/build_macos_dmg.sh [--ci]
#   --ci: Skip clean, pub get, and build steps (for CI where these are done separately)

set -e

# Parse arguments
CI_MODE=false
for arg in "$@"; do
    case $arg in
        --ci)
            CI_MODE=true
            shift
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Cyber Cultivation macOS DMG Builder ===${NC}"

# Get version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
VERSION_NUMBER=$(echo "$VERSION" | cut -d'+' -f1)

# Create dist folder for output
mkdir -p dist
DMG_NAME="dist/CyberCultivation-${VERSION_NUMBER}-macos.dmg"

echo -e "${YELLOW}Building version: $VERSION_NUMBER${NC}"

if [ "$CI_MODE" = false ]; then
    # Clean previous builds
    echo -e "${YELLOW}Cleaning previous builds...${NC}"
    flutter clean

    # Get dependencies
    echo -e "${YELLOW}Getting dependencies...${NC}"
    flutter pub get

    # Build release
    echo -e "${YELLOW}Building macOS release...${NC}"
    flutter build macos --release
else
    echo -e "${YELLOW}CI mode: Skipping clean, pub get, and build steps${NC}"
fi

APP_PATH="build/macos/Build/Products/Release/CyberCultivation.app"

# Check if build succeeded
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Build failed - app not found at $APP_PATH${NC}"
    exit 1
fi

# Ad-hoc sign the app (required for macOS to run unsigned apps)
echo -e "${YELLOW}Ad-hoc signing the app...${NC}"

# Sign all frameworks and dylibs first (deep signing)
find "$APP_PATH" -name "*.framework" -type d | while read framework; do
    echo "Signing: $framework"
    codesign --force --deep --sign - "$framework" 2>/dev/null || true
done

find "$APP_PATH" -name "*.dylib" -type f | while read dylib; do
    echo "Signing: $dylib"
    codesign --force --sign - "$dylib" 2>/dev/null || true
done

# Sign the main app bundle
echo "Signing main app bundle..."
codesign --force --deep --sign - "$APP_PATH"

# Verify the signature
echo -e "${YELLOW}Verifying signature...${NC}"
codesign --verify --verbose "$APP_PATH" && echo -e "${GREEN}Signature verified!${NC}" || echo -e "${RED}Signature verification failed${NC}"

# Create DMG
echo -e "${YELLOW}Creating DMG...${NC}"

# Remove old DMG if exists
rm -f "$DMG_NAME"

# Create a temporary directory for DMG contents
DMG_TEMP="dmg_temp_$$"
TEMP_DMG="temp_dmg_$$.dmg"

# Set up cleanup trap to ensure temp files are removed even on error
cleanup() {
    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    rm -f "$TEMP_DMG" 2>/dev/null || true
    rm -rf "$DMG_TEMP" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$DMG_TEMP"
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create a symbolic link to Applications folder
ln -s /Applications "$DMG_TEMP/Applications"

# DMG window settings
DMG_WINDOW_WIDTH=500
DMG_WINDOW_HEIGHT=300
ICON_SIZE=80
APP_ICON_X=120
APP_ICON_Y=150
APPLICATIONS_ICON_X=380
APPLICATIONS_ICON_Y=150

# Create a temporary writable DMG first
hdiutil create -volname "Cyber Cultivation" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDRW \
    "$TEMP_DMG"

# Mount the temporary DMG
VOLUME_NAME="Cyber Cultivation"
MOUNT_DIR="/Volumes/$VOLUME_NAME"

# Detach if already mounted
hdiutil detach "$MOUNT_DIR" 2>/dev/null || true

hdiutil attach -readwrite -noverify "$TEMP_DMG"
sleep 2

# Verify mount
if [ ! -d "$MOUNT_DIR" ]; then
    echo -e "${RED}Error: Failed to mount DMG at $MOUNT_DIR${NC}"
    rm -f "$TEMP_DMG"
    rm -rf "$DMG_TEMP"
    exit 1
fi

echo -e "${GREEN}DMG mounted at: $MOUNT_DIR${NC}"

# Use AppleScript to configure the DMG window appearance
echo -e "${YELLOW}Configuring DMG window appearance...${NC}"
osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, $((100 + DMG_WINDOW_WIDTH)), $((100 + DMG_WINDOW_HEIGHT))}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $ICON_SIZE
        set position of item "CyberCultivation.app" of container window to {$APP_ICON_X, $APP_ICON_Y}
        set position of item "Applications" of container window to {$APPLICATIONS_ICON_X, $APPLICATIONS_ICON_Y}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Unmount the temporary DMG
sync
sleep 1
hdiutil detach "$MOUNT_DIR" -force

# Convert to compressed read-only DMG
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_NAME"

# Note: Cleanup is handled by trap on EXIT

echo -e "${GREEN}=== Build Complete ===${NC}"
echo -e "${GREEN}DMG created: $DMG_NAME${NC}"
echo ""
echo -e "${YELLOW}To test the DMG:${NC}"
echo "1. Open the DMG file: open \"$DMG_NAME\""
echo "2. Drag the app to Applications"
echo "3. Right-click the app and select 'Open' (first time only)"
echo ""
echo -e "${YELLOW}Note: Since this is an unsigned build, macOS will show a security warning.${NC}"
echo "Users need to right-click -> Open, or go to System Preferences -> Security & Privacy to allow it."
