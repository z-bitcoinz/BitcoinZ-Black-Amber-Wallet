#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - iOS Rust Build Script
# Builds universal Rust library for iOS (device + simulator)

echo "🍎 Building Rust libraries for iOS..."

# Check if we're on macOS (required for iOS builds)
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: iOS builds require macOS"
    exit 1
fi

# Navigate to Rust project (correct directory)
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

# Install targets if needed
for target in "${TARGETS[@]}"; do
    if ! rustup target list --installed | grep -q "$target"; then
        echo "📦 Installing target: $target"
        rustup target add "$target" || {
            echo "⚠️  Could not add $target, skipping..."
            continue
        }
    fi
done

# Build for iOS device (ARM64)
echo "📱 Building for iOS devices (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS Simulator (x86_64 for Intel Macs)
echo "🖥️  Building for iOS Simulator x86_64..."
cargo build --release --target x86_64-apple-ios || {
    echo "⚠️  x86_64 simulator build failed (optional)"
}

# Build for iOS Simulator (ARM64 for Apple Silicon Macs)
echo "💻 Building for iOS Simulator ARM64..."
cargo build --release --target aarch64-apple-ios-sim || {
    echo "⚠️  ARM64 simulator build failed (optional)"
}

echo "🔗 Creating universal library..."

# Create universal library using lipo
# First, check which libraries were successfully built
LIBS_TO_COMBINE=()

if [ -f "target/aarch64-apple-ios/release/libbitcoinz_wallet_rust.a" ]; then
    LIBS_TO_COMBINE+=("target/aarch64-apple-ios/release/libbitcoinz_wallet_rust.a")
    echo "✅ Found iOS device library"
fi

if [ -f "target/x86_64-apple-ios/release/libbitcoinz_wallet_rust.a" ]; then
    LIBS_TO_COMBINE+=("target/x86_64-apple-ios/release/libbitcoinz_wallet_rust.a")
    echo "✅ Found x86_64 simulator library"
fi

if [ -f "target/aarch64-apple-ios-sim/release/libbitcoinz_wallet_rust.a" ]; then
    LIBS_TO_COMBINE+=("target/aarch64-apple-ios-sim/release/libbitcoinz_wallet_rust.a")
    echo "✅ Found ARM64 simulator library"
fi

# Check if we have at least the device library
if [ ${#LIBS_TO_COMBINE[@]} -eq 0 ]; then
    echo "❌ No iOS libraries were built successfully"
    exit 1
fi

# Create universal library
if [ ${#LIBS_TO_COMBINE[@]} -gt 1 ]; then
    echo "📦 Creating universal library from ${#LIBS_TO_COMBINE[@]} architectures..."
    lipo -create "${LIBS_TO_COMBINE[@]}" -output "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
else
    echo "📦 Copying single architecture library..."
    cp "${LIBS_TO_COMBINE[0]}" "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
fi

# Verify the library was created and show its size
if [ -f "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a" ]; then
    LIBRARY_SIZE=$(ls -lh "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a" | awk '{print $5}')
    echo "✅ iOS universal library created successfully"
    echo "📏 Library size: $LIBRARY_SIZE"
    echo "📍 Location: $IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
    
    # Show architectures in the universal library
    echo "🏗️  Architectures in universal library:"
    lipo -info "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
else
    echo "❌ Failed to create iOS library"
    exit 1
fi

cd ..

echo "🎉 iOS Rust build completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Run: flutter build ios --release"
echo "   2. The library will be automatically linked by Xcode"
echo ""
echo "💡 Note: The library includes embedded Zcash params (~49MB)"