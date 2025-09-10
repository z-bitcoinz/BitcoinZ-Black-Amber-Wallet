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
BUILT_TARGETS=()
for target in "${TARGETS[@]}"; do
    echo "🖥️ Building for $target..."
    
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

# Build lipo command with only successfully built targets for static library
LIPO_INPUTS_A=()
LIPO_INPUTS_DYLIB=()
for target in "${BUILT_TARGETS[@]}"; do
    lib_a="target/$target/release/libbitcoinz_wallet_rust.a"
    lib_dylib="target/$target/release/libbitcoinz_wallet_rust.dylib"
    
    if [ -f "$lib_a" ]; then
        LIPO_INPUTS_A+=("$lib_a")
    else
        echo "⚠️  Static library not found for $target: $lib_a"
    fi
    
    if [ -f "$lib_dylib" ]; then
        LIPO_INPUTS_DYLIB+=("$lib_dylib")
    else
        echo "⚠️  Dynamic library not found for $target: $lib_dylib"
    fi
done

# Create universal static library
if [ ${#LIPO_INPUTS_A[@]} -eq 1 ]; then
    echo "🖥️  Only one target available for static library, copying..."
    cp "${LIPO_INPUTS_A[0]}" "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
elif [ ${#LIPO_INPUTS_A[@]} -gt 1 ]; then
    echo "🖥️  Creating universal static library from ${#LIPO_INPUTS_A[@]} targets..."
    lipo -create "${LIPO_INPUTS_A[@]}" -output "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.a"
else
    echo "❌ No valid static libraries found!"
    exit 1
fi

# Create universal dynamic library
if [ ${#LIPO_INPUTS_DYLIB[@]} -eq 1 ]; then
    echo "🖥️  Only one target available for dynamic library, copying..."
    cp "${LIPO_INPUTS_DYLIB[0]}" "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.dylib"
elif [ ${#LIPO_INPUTS_DYLIB[@]} -gt 1 ]; then
    echo "🖥️  Creating universal dynamic library from ${#LIPO_INPUTS_DYLIB[@]} targets..."
    lipo -create "${LIPO_INPUTS_DYLIB[@]}" -output "$MACOS_FRAMEWORKS_DIR/libbitcoinz_wallet_rust.dylib"
else
    echo "⚠️  No valid dynamic libraries found, skipping dylib creation..."
fi

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