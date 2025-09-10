#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - macOS Rust Build Script
# Builds universal Rust library for macOS (Intel + Apple Silicon)

echo "🖥️ Building Rust libraries for macOS..."

# Navigate to Rust project
cd rust

# macOS targets
TARGETS=(
    "x86_64-apple-darwin"        # Intel Macs
    "aarch64-apple-darwin"       # Apple Silicon Macs
)

# macOS Frameworks output directory (for Flutter macOS)
MACOS_FRAMEWORKS_DIR="../macos/Frameworks"
mkdir -p "$MACOS_FRAMEWORKS_DIR"

echo "🔨 Building for macOS targets..."

# Build for each target
for target in "${TARGETS[@]}"; do
    echo "🖥️ Building for $target..."
    
    # Clean previous build
    cargo clean --target "$target"
    
    # Build with release optimizations
    cargo build --release --target "$target"
    
    echo "✅ Built $target successfully"
done

echo "🔗 Creating universal library..."

# Create universal library using lipo
lipo -create \
    "target/x86_64-apple-darwin/release/libbitcoinz_wallet_rust.a" \
    "target/aarch64-apple-darwin/release/libbitcoinz_wallet_rust.a" \
    -output "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"

# Also create the dylib version for Flutter macOS
lipo -create \
    "target/x86_64-apple-darwin/release/libbitcoinz_wallet_rust.dylib" \
    "target/aarch64-apple-darwin/release/libbitcoinz_wallet_rust.dylib" \
    -output "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.dylib"

echo "🎉 macOS Rust build completed!"
echo "📁 Universal libraries created at: $MACOS_FRAMEWORKS_DIR/"

# Display library info
echo "📊 Static library (.a) info:"
file "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
ls -lh "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"

echo "📊 Dynamic library (.dylib) info:"
file "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.dylib"
ls -lh "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.dylib"

# Verify architectures
echo "🔍 Static library architectures:"
lipo -info "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"

echo "🔍 Dynamic library architectures:"
lipo -info "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.dylib"