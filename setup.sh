#!/bin/bash

# tickler Setup Script
# This script generates the Xcode project using xcodegen

set -e

echo "tickler Setup"
echo "============="

# Check for xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "Error: Homebrew not found. Please install xcodegen manually:"
        echo "  brew install xcodegen"
        exit 1
    fi
fi

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "Setup complete! You can now:"
echo "  1. Open tickler.xcodeproj in Xcode"
echo "  2. Select your signing team in project settings"
echo "  3. Build and run (Cmd+R)"
echo ""
echo "The app will appear in your menu bar."
