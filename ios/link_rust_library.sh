#!/bin/bash
# Link Rust library for iOS builds

RUST_LIB="$SRCROOT/Frameworks/libbitcoinz_wallet_rust.a"

if [ -f "$RUST_LIB" ]; then
    echo "Linking Rust library: $RUST_LIB"
    # The library will be linked by Xcode
else
    echo "Warning: Rust library not found at $RUST_LIB"
    exit 0  # Don't fail the build
fi