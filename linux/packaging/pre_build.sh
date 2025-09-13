#!/bin/bash
# Pre-build hook for flutter_distributor
# This script runs before each package build to ensure Rust library is present

echo "🔧 Pre-build hook: Ensuring Rust library is present..."

RUST_LIB="libbitcoinz_wallet_rust.so"
BACKUP_PATH="/tmp/${RUST_LIB}.backup"

# Check if we have a backup
if [ -f "$BACKUP_PATH" ]; then
    echo "📦 Restoring Rust library from backup..."
    
    # Restore to linux directory
    mkdir -p linux
    cp "$BACKUP_PATH" "linux/$RUST_LIB"
    
    # Also copy to native_assets for CMake
    mkdir -p build/native_assets/linux
    cp "$BACKUP_PATH" "build/native_assets/linux/$RUST_LIB"
    
    echo "✅ Rust library restored ($(ls -lh linux/$RUST_LIB | awk '{print $5}'))"
else
    echo "⚠️ No Rust library backup found, checking if it exists locally..."
    if [ -f "linux/$RUST_LIB" ]; then
        echo "✅ Rust library already present"
    else
        echo "❌ ERROR: Rust library not found!"
        exit 1
    fi
fi