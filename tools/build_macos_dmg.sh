#!/bin/bash
# Local script to build macOS DMG
# Usage: ./tools/build_macos_dmg.sh

set -e

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

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
flutter clean

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get

# Build release
echo -e "${YELLOW}Building macOS release...${NC}"
flutter build macos --release

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
mkdir -p "$DMG_TEMP"
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create a symbolic link to Applications folder
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG using hdiutil
hdiutil create -volname "Cyber Cultivation" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_NAME"

# Clean up
rm -rf "$DMG_TEMP"

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
