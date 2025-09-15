#!/bin/bash
set -e

echo "🍎 Creating macOS DMG installer..."

# Navigate to the build directory
cd build/macos/Build/Products/Release

# Find the app name
APP_NAME=$(ls -d *.app | head -1)
if [ -z "$APP_NAME" ]; then
    echo "❌ No .app bundle found!"
    exit 1
fi

echo "📦 Found app: $APP_NAME"
APP_BASE_NAME="${APP_NAME%.app}"

# Clean up any existing DMG
DMG_NAME="BitcoinZ-Black-Amber.dmg"
[ -f "$DMG_NAME" ] && rm "$DMG_NAME"

# Check if create-dmg is available
if command -v create-dmg &> /dev/null; then
    echo "✅ Using create-dmg for professional installer..."
    
    # Create a temporary directory for DMG contents
    DMG_TEMP="dmg_temp"
    rm -rf "$DMG_TEMP"
    mkdir "$DMG_TEMP"
    
    # Copy app to temp directory
    cp -R "$APP_NAME" "$DMG_TEMP/"
    
    # Add instruction text file as visual cue
    echo "➜ Drag BitcoinZ Black Amber to Applications folder to install" > "$DMG_TEMP/Install Instructions.txt"
    
    # Create DMG with professional layout
    create-dmg \
        --volname "BitcoinZ Black Amber" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --text-size 14 \
        --icon-size 100 \
        --icon "$APP_NAME" 150 250 \
        --hide-extension "$APP_NAME" \
        --app-drop-link 450 250 \
        --icon "Install Instructions.txt" 300 100 \
        --no-internet-enable \
        --format UDZO \
        --hdiutil-quiet \
        "$DMG_NAME" \
        "$DMG_TEMP/" || {
            echo "⚠️ create-dmg failed, falling back to hdiutil..."
            # Fallback to simple DMG
            hdiutil create -volname "BitcoinZ Black Amber" \
                -srcfolder "$APP_NAME" \
                -ov -format UDZO \
                "$DMG_NAME"
        }
    
    # Clean up temp directory
    rm -rf "$DMG_TEMP"
    
else
    echo "⚠️ create-dmg not found, using hdiutil for basic DMG..."
    
    # Create a simple DMG with hdiutil
    # First create a temporary directory structure
    DMG_TEMP="dmg_temp"
    rm -rf "$DMG_TEMP"
    mkdir "$DMG_TEMP"
    
    # Copy app to temp directory
    cp -R "$APP_NAME" "$DMG_TEMP/"
    
    # Create Applications symlink
    ln -s /Applications "$DMG_TEMP/Applications"
    
    # Add instruction text file
    echo "➜ Drag BitcoinZ Black Amber to Applications folder to install" > "$DMG_TEMP/Install Instructions.txt"
    
    # Create DMG from temp directory
    hdiutil create -volname "BitcoinZ Black Amber" \
        -srcfolder "$DMG_TEMP" \
        -ov -format UDZO \
        "$DMG_NAME"
    
    # Clean up
    rm -rf "$DMG_TEMP"
fi

# Verify DMG was created
if [ -f "$DMG_NAME" ]; then
    echo "✅ DMG created successfully!"
    ls -lh "$DMG_NAME"
else
    echo "❌ Failed to create DMG"
    exit 1
fi