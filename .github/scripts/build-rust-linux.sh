#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - Linux Rust Build Script
# Builds Rust library for Linux x86_64

echo "🐧 Building Rust libraries for Linux..."

# Navigate to Rust project
cd rust

# Linux target
TARGET="x86_64-unknown-linux-gnu"

# Linux library output directory (for Flutter Linux)
LINUX_LIBS_DIR="../linux"
mkdir -p "$LINUX_LIBS_DIR"

echo "🔨 Building for Linux target: $TARGET..."

# Clean previous build
cargo clean --target "$TARGET"

# Build with release optimizations
cargo build --release --target "$TARGET"

echo "📦 Copying libraries to Flutter Linux directories..."

# Copy shared library for Flutter Linux
cp "target/$TARGET/release/libbitcoinz_wallet_rust.so" "$LINUX_LIBS_DIR/"

# Also copy static library (may be needed)
cp "target/$TARGET/release/libbitcoinz_wallet_rust.a" "$LINUX_LIBS_DIR/"

# IMPORTANT: Also copy to native_assets directory for CMake bundling
NATIVE_ASSETS_DIR="../build/native_assets/linux"
echo "📦 Creating native_assets directory for CMake..."
mkdir -p "$NATIVE_ASSETS_DIR"
cp "target/$TARGET/release/libbitcoinz_wallet_rust.so" "$NATIVE_ASSETS_DIR/"
echo "✅ Copied library to native_assets for bundling: $NATIVE_ASSETS_DIR/"

echo "🎉 Linux Rust build completed!"
echo "📁 Libraries copied to: $LINUX_LIBS_DIR/"

# Display library info
echo "📊 Shared library (.so) info:"
file "$LINUX_LIBS_DIR/libbitcoinz_wallet_rust.so"
ls -lh "$LINUX_LIBS_DIR/libbitcoinz_wallet_rust.so"

echo "📊 Static library (.a) info:"
file "$LINUX_LIBS_DIR/libbitcoinz_wallet_rust.a"
ls -lh "$LINUX_LIBS_DIR/libbitcoinz_wallet_rust.a"

# Check dependencies
echo "🔗 Dynamic library dependencies:"
ldd "$LINUX_LIBS_DIR/libbitcoinz_wallet_rust.so" || true