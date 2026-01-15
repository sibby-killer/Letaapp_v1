#!/bin/bash
# Leta App - Automated Build Script
# Run this script after applying all fixes

set -e

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "   🚀 LETA APP - BUILD SCRIPT"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Step 1: Check Flutter
echo "📋 [1/6] Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter not found!"
    echo "   Please install Flutter from: https://flutter.dev"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d' ' -f2)
echo "✅ Flutter version: $FLUTTER_VERSION"
echo ""

# Step 2: Check Flutter Version
echo "📋 [2/6] Verifying Flutter version..."
REQUIRED_VERSION="3.16.0"
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$FLUTTER_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "⚠️  WARNING: Flutter version should be 3.16.0 or higher"
    echo "   Current version: $FLUTTER_VERSION"
    echo "   Run: flutter upgrade"
    read -p "   Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo "✅ Flutter version OK"
echo ""

# Step 3: Clean Project
echo "📋 [3/6] Cleaning project..."
flutter clean
echo "✅ Clean complete"
echo ""

# Step 4: Get Dependencies
echo "📋 [4/6] Installing dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to get dependencies"
    exit 1
fi
echo "✅ Dependencies installed"
echo ""

# Step 5: Run Analyzer
echo "📋 [5/6] Running analyzer..."
flutter analyze --no-fatal-infos --no-fatal-warnings
echo ""

# Step 6: Check Device
echo "📋 [6/6] Checking for connected devices..."
flutter devices
echo ""

# Prompt to build
echo "═══════════════════════════════════════════════════════════"
echo "   ✅ SETUP COMPLETE!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Connect your Android device via USB"
echo "2. Enable USB Debugging on your device"
echo "3. Run one of these commands:"
echo ""
echo "   flutter run              (debug build)"
echo "   flutter run --release    (release build)"
echo "   flutter build apk        (build APK file)"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
