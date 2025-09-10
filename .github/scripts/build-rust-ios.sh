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
)

# iOS Frameworks output directory
IOS_FRAMEWORKS_DIR="../ios/Frameworks"
mkdir -p "$IOS_FRAMEWORKS_DIR"

echo "🔨 Building for iOS targets..."

# Build for each target
BUILT_TARGETS=()
for target in "${TARGETS[@]}"; do
    echo "🍎 Building for $target..."
    
    # Check if target is installed
    if ! rustup target list --installed | grep -q "$target"; then
        echo "⚠️  Target $target not installed, adding..."
        rustup target add "$target" || {
            echo "❌ Failed to add target $target, skipping..."
            continue
        }
    fi
    
    # Clean previous build
    cargo clean --target "$target"
    
    # Build with release optimizations
    if cargo build --release --target "$target"; then
        echo "✅ Built $target successfully"
        BUILT_TARGETS+=("$target")
    else
        echo "❌ Failed to build $target, continuing with other targets..."
    fi
done

# Check if we have at least one successful build
if [ ${#BUILT_TARGETS[@]} -eq 0 ]; then
    echo "❌ No targets built successfully!"
    exit 1
fi

echo "📊 Successfully built targets: ${BUILT_TARGETS[*]}"

echo "🔗 Creating universal library..."

# Build lipo command with only successfully built targets
LIPO_INPUTS=()
for target in "${BUILT_TARGETS[@]}"; do
    lib_path="target/$target/release/libbitcoinz_wallet_rust.a"
    if [ -f "$lib_path" ]; then
        LIPO_INPUTS+=("$lib_path")
    else
        echo "⚠️  Library not found for $target: $lib_path"
    fi
done

# Create universal library using lipo with available targets
if [ ${#LIPO_INPUTS[@]} -eq 1 ]; then
    echo "📱 Only one target available, copying single library..."
    cp "${LIPO_INPUTS[0]}" "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
elif [ ${#LIPO_INPUTS[@]} -gt 1 ]; then
    echo "📱 Creating universal library from ${#LIPO_INPUTS[@]} targets..."
    lipo -create "${LIPO_INPUTS[@]}" -output "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
else
    echo "❌ No valid libraries found to create universal binary!"
    exit 1
fi

echo "🎉 iOS Rust build completed!"
echo "📁 Universal library created at: $IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"

# Display library info
echo "📊 Universal library info:"
file "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
ls -lh "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"

# Verify architectures
echo "🔍 Supported architectures:"
lipo -info "$IOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"