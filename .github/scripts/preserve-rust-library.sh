#!/bin/bash
set -e

# Script to preserve and restore Rust library during flutter_distributor packaging
# flutter_distributor runs flutter clean which removes the Rust library

RUST_LIB_NAME="libbitcoinz_wallet_rust.so"
RUST_LIB_SOURCE="linux/$RUST_LIB_NAME"
RUST_LIB_BACKUP="/tmp/$RUST_LIB_NAME.backup"

# Function to backup the Rust library
backup_rust_lib() {
    if [ -f "$RUST_LIB_SOURCE" ]; then
        cp "$RUST_LIB_SOURCE" "$RUST_LIB_BACKUP"
        echo "✅ Rust library backed up: $(ls -lh $RUST_LIB_BACKUP | awk '{print $5}')"
        return 0
    else
        echo "❌ ERROR: Rust library not found at $RUST_LIB_SOURCE"
        return 1
    fi
}

# Function to restore the Rust library
restore_rust_lib() {
    if [ -f "$RUST_LIB_BACKUP" ]; then
        # Restore to linux directory
        mkdir -p linux
        cp "$RUST_LIB_BACKUP" "$RUST_LIB_SOURCE"
        echo "✅ Rust library restored to $RUST_LIB_SOURCE"
        
        # Also copy to build bundle if it exists
        if [ -d "build/linux/x64/release/bundle/lib" ]; then
            cp "$RUST_LIB_BACKUP" "build/linux/x64/release/bundle/lib/"
            echo "✅ Rust library copied to bundle/lib"
        fi
        
        # Copy to native_assets for CMake
        if [ -d "build/native_assets/linux" ]; then
            cp "$RUST_LIB_BACKUP" "build/native_assets/linux/"
            echo "✅ Rust library copied to native_assets"
        fi
        return 0
    else
        echo "❌ ERROR: Rust library backup not found at $RUST_LIB_BACKUP"
        return 1
    fi
}

# Main logic
case "${1:-}" in
    backup)
        backup_rust_lib
        ;;
    restore)
        restore_rust_lib
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        echo "  backup  - Save the Rust library to /tmp"
        echo "  restore - Restore the Rust library from /tmp"
        exit 1
        ;;
esac