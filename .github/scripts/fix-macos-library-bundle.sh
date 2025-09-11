#!/bin/bash
set -e

# Fix macOS library bundling - ensure Rust libraries are copied into the app bundle
echo "🖥️ Fixing macOS library bundling..."

# After building the macOS app, we need to copy the Rust libraries into the app bundle
APP_PATH="build/macos/Build/Products/Release"

# Find the app bundle
APP_BUNDLE=$(find "$APP_PATH" -name "*.app" -type d | head -1)

if [ -z "$APP_BUNDLE" ]; then
    echo "❌ No app bundle found in $APP_PATH"
    exit 1
fi

echo "📦 Found app bundle: $APP_BUNDLE"

# Create Frameworks directory in the app bundle if it doesn't exist
FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
mkdir -p "$FRAMEWORKS_DIR"

# Copy Rust libraries from macos/Frameworks to the app bundle
if [ -d "macos/Frameworks" ]; then
    echo "📋 Copying Rust libraries to app bundle..."
    
    # Copy dylib (dynamic library)
    if [ -f "macos/Frameworks/libbitcoinz_wallet_rust.dylib" ]; then
        cp "macos/Frameworks/libbitcoinz_wallet_rust.dylib" "$FRAMEWORKS_DIR/"
        echo "✅ Copied dynamic library to app bundle"
        
        # Update the library's install name to use @rpath
        install_name_tool -id "@rpath/libbitcoinz_wallet_rust.dylib" "$FRAMEWORKS_DIR/libbitcoinz_wallet_rust.dylib"
        echo "✅ Updated library install name"
    fi
    
    # The static library (.a) doesn't need to be in the final bundle
    # It's only used during compilation
else
    echo "⚠️ macos/Frameworks directory not found"
fi

# Verify the libraries are in the app bundle
echo "📊 App bundle Frameworks contents:"
ls -lh "$FRAMEWORKS_DIR"/*.dylib 2>/dev/null || echo "No dylib files found"

# Check total app size
echo "📏 Total app bundle size:"
du -sh "$APP_BUNDLE"

echo "✅ macOS library bundling fix complete"