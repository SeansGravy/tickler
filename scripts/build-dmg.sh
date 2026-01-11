#!/bin/bash

# build-dmg.sh - Build an unsigned DMG for tickler
# Usage: ./scripts/build-dmg.sh

set -e

# Configuration
SCHEME_NAME="tickler"
APP_NAME="Tickler"
DMG_NAME="Tickler"
BUILD_DIR="build"
DMG_DIR="${BUILD_DIR}/dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building ${APP_NAME}...${NC}"

# Clean previous build
rm -rf "${BUILD_DIR}/Release"
rm -rf "${DMG_DIR}"
rm -f "${DMG_PATH}"

# Build the app
xcodebuild -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -destination 'platform=macOS' \
    build

# Find the built app
APP_PATH=$(find "${BUILD_DIR}/DerivedData" -name "${APP_NAME}.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}Error: Could not find ${APP_NAME}.app${NC}"
    exit 1
fi

echo -e "${GREEN}Found app at: ${APP_PATH}${NC}"

# Create DMG directory structure
echo -e "${GREEN}Creating DMG structure...${NC}"
mkdir -p "${DMG_DIR}"

# Copy app to DMG directory
cp -R "${APP_PATH}" "${DMG_DIR}/"

# Create Applications symlink
ln -s /Applications "${DMG_DIR}/Applications"

# Create background directory and placeholder
mkdir -p "${DMG_DIR}/.background"

# Create a simple background image placeholder (512x320)
# In production, replace this with an actual background image
cat > "${DMG_DIR}/.background/README.txt" << 'EOF'
Place your DMG background image here as "background.png" (512x320 recommended)
EOF

# Create DMG
echo -e "${GREEN}Creating DMG...${NC}"

# Calculate size (app size + 20MB buffer)
SIZE=$(du -sm "${DMG_DIR}" | cut -f1)
SIZE=$((SIZE + 20))

# Create temporary DMG
hdiutil create -srcfolder "${DMG_DIR}" \
    -volname "${VOLUME_NAME}" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${SIZE}m \
    "${BUILD_DIR}/temp.dmg"

# Mount the DMG
echo -e "${GREEN}Configuring DMG appearance...${NC}"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${BUILD_DIR}/temp.dmg" | grep -E '^/dev/' | head -1 | awk '{print $1}')
MOUNT_POINT="/Volumes/${VOLUME_NAME}"

# Wait for mount
sleep 2

# Set DMG window properties using AppleScript
osascript << EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 912, 480}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "${APP_NAME}.app" of container window to {130, 180}
        set position of item "Applications" of container window to {380, 180}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Sync and unmount
sync
hdiutil detach "${DEVICE}"

# Convert to compressed DMG
echo -e "${GREEN}Compressing DMG...${NC}"
hdiutil convert "${BUILD_DIR}/temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${DMG_PATH}"

# Clean up
rm -f "${BUILD_DIR}/temp.dmg"
rm -rf "${DMG_DIR}"

# Get final DMG size
DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DMG created successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Output: ${YELLOW}${DMG_PATH}${NC}"
echo -e "Size:   ${YELLOW}${DMG_SIZE}${NC}"
echo ""
echo -e "${YELLOW}Note: This DMG is unsigned. Users will need to:${NC}"
echo -e "  1. Right-click the app and select 'Open'"
echo -e "  2. Click 'Open' in the Gatekeeper dialog"
echo ""
