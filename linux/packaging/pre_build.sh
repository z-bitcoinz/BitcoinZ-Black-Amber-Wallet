#!/bin/bash
# Pre-build hook for flutter_distributor
# This script runs before each package build to ensure Rust library is present

echo "🔧 Pre-build hook: Ensuring Rust library is present..."

RUST_LIB="libbitcoinz_wallet_rust.so"
BACKUP_PATH="/tmp/${RUST_LIB}.backup"

# Check if we have a backup
if [ -f "$BACKUP_PATH" ]; then
    echo "📦 Restoring Rust library from backup ($(ls -lh $BACKUP_PATH | awk '{print $5}'))..."

    # Restore to linux directory
    mkdir -p linux
    cp "$BACKUP_PATH" "linux/$RUST_LIB"

    # Also copy to native_assets for CMake (critical for bundling)
    mkdir -p build/native_assets/linux
    cp "$BACKUP_PATH" "build/native_assets/linux/$RUST_LIB"

    # Set proper permissions
    chmod 755 "linux/$RUST_LIB"
    chmod 755 "build/native_assets/linux/$RUST_LIB"

    echo "✅ Rust library restored ($(ls -lh linux/$RUST_LIB | awk '{print $5}'))"
    echo "✅ Rust library copied to native_assets for CMake bundling"
else
    echo "⚠️ No Rust library backup found, checking if it exists locally..."
    if [ -f "linux/$RUST_LIB" ]; then
        echo "✅ Rust library already present ($(ls -lh linux/$RUST_LIB | awk '{print $5}'))"
        # Ensure it's also in native_assets
        mkdir -p build/native_assets/linux
        cp "linux/$RUST_LIB" "build/native_assets/linux/$RUST_LIB"
        chmod 755 "build/native_assets/linux/$RUST_LIB"
        echo "✅ Rust library copied to native_assets"
    else
        echo "❌ ERROR: Rust library not found!"
        echo "Expected locations:"
        echo "  - linux/$RUST_LIB"
        echo "  - $BACKUP_PATH"
        exit 1
    fi
fi