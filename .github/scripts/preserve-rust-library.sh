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
        echo "🔄 Restoring Rust library from backup ($(ls -lh $RUST_LIB_BACKUP | awk '{print $5}'))..."

        # Restore to linux directory (primary location)
        mkdir -p linux
        cp "$RUST_LIB_BACKUP" "$RUST_LIB_SOURCE"
        echo "✅ Rust library restored to $RUST_LIB_SOURCE"

        # Copy to native_assets for CMake (critical for flutter_distributor)
        mkdir -p build/native_assets/linux
        cp "$RUST_LIB_BACKUP" "build/native_assets/linux/$RUST_LIB_NAME"
        echo "✅ Rust library copied to native_assets for CMake bundling"

        # Also copy to build bundle if it exists (for manual builds)
        if [ -d "build/linux/x64/release/bundle/lib" ]; then
            cp "$RUST_LIB_BACKUP" "build/linux/x64/release/bundle/lib/$RUST_LIB_NAME"
            echo "✅ Rust library copied to existing bundle/lib"
        fi

        # Ensure proper permissions
        chmod 755 "$RUST_LIB_SOURCE"
        chmod 755 "build/native_assets/linux/$RUST_LIB_NAME"

        # Verify restoration
        echo "📊 Restored library info:"
        file "$RUST_LIB_SOURCE"
        ls -lh "$RUST_LIB_SOURCE"

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