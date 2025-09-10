#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - iOS Rust Build Script
# Builds universal Rust library for iOS (device + simulator)

echo "🍎 Building Rust libraries for iOS..."

# Navigate to Rust project
cd rust

# iOS targets
TARGETS=(
    "aarch64-apple-ios"          # iOS devices (iPhone/iPad)
    "x86_64-apple-ios"           # iOS Simulator (Intel)
    "aarch64-apple-ios-sim"      # iOS Simulator (Apple Silicon)
)

# iOS Frameworks output directory
IOS_FRAMEWORKS_DIR="../ios/Frameworks"
mkdir -p "$IOS_FRAMEWORKS_DIR"

echo "🔨 Building for iOS targets..."

# Build for each target
for target in "${TARGETS[@]}"; do
    echo "🍎 Building for $target..."
    
    # Clean previous build
    cargo clean --target "$target"
    
    # Build with release optimizations
    cargo build --release --target "$target"
    
    echo "✅ Built $target successfully"
done

echo "🔗 Creating universal library..."

# Create universal library using lipo
lipo -create \
    "target/aarch64-apple-ios/release/libbitcoinz_wallet_rust.a" \
    "target/x86_64-apple-ios/release/libbitcoinz_wallet_rust.a" \
    "target/aarch64-apple-ios-sim/release/libbitcoinz_wallet_rust.a" \
    -output "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"

echo "🎉 iOS Rust build completed!"
echo "📁 Universal library created at: $IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"

# Display library info
echo "📊 Universal library info:"
file "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
ls -lh "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"

# Verify architectures
echo "🔍 Supported architectures:"
lipo -info "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"