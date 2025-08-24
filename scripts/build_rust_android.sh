#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - Android Build Script
# This script compiles the Rust core library for Android targets

echo "🔧 Building BitcoinZ Mobile Wallet for Android..."

# Check if we're in the right directory
if [ ! -f "rust_core/Cargo.toml" ]; then
    echo "❌ Error: This script must be run from the bitcoinz-mobile-wallet root directory"
    exit 1
fi

# Check if Android NDK is installed
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "❌ Error: ANDROID_NDK_HOME environment variable is not set"
    echo "Please install Android NDK and set ANDROID_NDK_HOME"
    exit 1
fi

# Android targets to build for
ANDROID_TARGETS=(
    "aarch64-linux-android"    # ARM64 (most modern devices)
    "armv7-linux-androideabi"  # ARM32 (older devices)
    "x86_64-linux-android"     # x86_64 (emulators)
    "i686-linux-android"       # x86 (older emulators)
)

# Create output directories
mkdir -p flutter_app/android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64,x86}

cd rust_core

echo "📋 Installing Rust targets for Android..."
for target in "${ANDROID_TARGETS[@]}"; do
    rustup target add $target
done

# Set up environment variables for Android NDK
API_LEVEL=21  # Android 5.0 (minimum supported version)
NDK_TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64"

# Export environment variables for cross-compilation
export CC_aarch64_linux_android="$NDK_TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang"
export AR_aarch64_linux_android="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$NDK_TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang"

export CC_armv7_linux_androideabi="$NDK_TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang"
export AR_armv7_linux_androideabi="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="$NDK_TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang"

export CC_x86_64_linux_android="$NDK_TOOLCHAIN/bin/x86_64-linux-android${API_LEVEL}-clang"
export AR_x86_64_linux_android="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="$NDK_TOOLCHAIN/bin/x86_64-linux-android${API_LEVEL}-clang"

export CC_i686_linux_android="$NDK_TOOLCHAIN/bin/i686-linux-android${API_LEVEL}-clang"
export AR_i686_linux_android="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_I686_LINUX_ANDROID_LINKER="$NDK_TOOLCHAIN/bin/i686-linux-android${API_LEVEL}-clang"

echo "🚀 Building for Android targets..."

# Build for ARM64 (most important)
echo "📱 Building for ARM64 (aarch64-linux-android)..."
cargo build --target aarch64-linux-android --release
cp target/aarch64-linux-android/release/libbitcoinz_wallet_rust.so ../flutter_app/android/app/src/main/jniLibs/arm64-v8a/

# Build for ARM32
echo "📱 Building for ARM32 (armv7-linux-androideabi)..."
cargo build --target armv7-linux-androideabi --release
cp target/armv7-linux-androideabi/release/libbitcoinz_wallet_rust.so ../flutter_app/android/app/src/main/jniLibs/armeabi-v7a/

# Build for x86_64 (emulators)
echo "🖥️  Building for x86_64 (x86_64-linux-android)..."
cargo build --target x86_64-linux-android --release
cp target/x86_64-linux-android/release/libbitcoinz_wallet_rust.so ../flutter_app/android/app/src/main/jniLibs/x86_64/

# Build for x86 (older emulators)
echo "🖥️  Building for x86 (i686-linux-android)..."
cargo build --target i686-linux-android --release
cp target/i686-linux-android/release/libbitcoinz_wallet_rust.so ../flutter_app/android/app/src/main/jniLibs/x86/

cd ..

echo "✅ Android build completed successfully!"
echo "📦 Native libraries copied to flutter_app/android/app/src/main/jniLibs/"
echo ""
echo "📋 Next steps:"
echo "   1. cd flutter_app"
echo "   2. flutter build apk"
echo "   or"
echo "   flutter build appbundle"