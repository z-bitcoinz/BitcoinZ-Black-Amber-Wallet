#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - Android Rust Build Script
# Builds Rust libraries for all Android architectures

echo "🤖 Building Rust libraries for Android..."

# Navigate to Rust project
cd rust

# Verify NDK is available
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "❌ ANDROID_NDK_HOME not set!"
    exit 1
fi

echo "📱 Using Android NDK: $ANDROID_NDK_HOME"

# Android build configuration
export CC_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"
export CXX_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++"
export AR_aarch64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"

export CC_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang"
export CXX_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang++"
export AR_armv7_linux_androideabi="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang"

export CC_x86_64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang"
export CXX_x86_64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang++"
export AR_x86_64_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang"

export CC_i686_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang"
export CXX_i686_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang++"
export AR_i686_linux_android="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
export CARGO_TARGET_I686_LINUX_ANDROID_LINKER="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang"

# Build targets
TARGETS=(
    "aarch64-linux-android"
    "armv7-linux-androideabi"
    "x86_64-linux-android"
    "i686-linux-android"
)

# Android library output directories
ANDROID_LIBS_DIR="../android/app/src/main/jniLibs"
ABI_DIRS=(
    "arm64-v8a"
    "armeabi-v7a"
    "x86_64"
    "x86"
)

# Ensure output directories exist
for abi_dir in "${ABI_DIRS[@]}"; do
    mkdir -p "$ANDROID_LIBS_DIR/$abi_dir"
done

echo "🔨 Building for Android targets..."

# Build for each target
for i in "${!TARGETS[@]}"; do
    target="${TARGETS[i]}"
    abi_dir="${ABI_DIRS[i]}"
    
    echo "📱 Building for $target -> $abi_dir..."
    
    # Clean previous build
    cargo clean --target "$target"
    
    # Build with release optimizations
    cargo build --release --target "$target"
    
    # Copy library to Android jniLibs directory
    cp "target/$target/release/libbitcoinz_wallet_rust.so" "$ANDROID_LIBS_DIR/$abi_dir/"
    
    echo "✅ Built $target successfully"
done

echo "🎉 Android Rust build completed!"
echo "📁 Libraries copied to: $ANDROID_LIBS_DIR"

# Display library sizes
echo "📊 Library sizes:"
find "$ANDROID_LIBS_DIR" -name "*.so" -exec ls -lh {} \;