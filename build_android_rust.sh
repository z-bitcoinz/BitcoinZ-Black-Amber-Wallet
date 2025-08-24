#!/bin/bash
set -e

echo "🔧 Building BitcoinZ Rust libraries for Android..."

# Use rustup's Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Set Android NDK
export ANDROID_NDK_HOME="/Users/name/Library/Android/sdk/ndk/26.3.11579264"
NDK_TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64"
export PATH="$NDK_TOOLCHAIN/bin:$PATH"

# API level
API_LEVEL=21

# Set up environment for each target
export CC_aarch64_linux_android="$NDK_TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang"
export CXX_aarch64_linux_android="$NDK_TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang++"
export AR_aarch64_linux_android="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$CC_aarch64_linux_android"

export CC_armv7_linux_androideabi="$NDK_TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang"
export CXX_armv7_linux_androideabi="$NDK_TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang++"
export AR_armv7_linux_androideabi="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="$CC_armv7_linux_androideabi"

export CC_x86_64_linux_android="$NDK_TOOLCHAIN/bin/x86_64-linux-android${API_LEVEL}-clang"
export CXX_x86_64_linux_android="$NDK_TOOLCHAIN/bin/x86_64-linux-android${API_LEVEL}-clang++"
export AR_x86_64_linux_android="$NDK_TOOLCHAIN/bin/llvm-ar"
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="$CC_x86_64_linux_android"

# Create output directories
mkdir -p flutter_app/android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}

cd rust_core

# Build for ARM64 (most important)
echo "📱 Building for ARM64..."
cargo build --target aarch64-linux-android --release
if [ -f target/aarch64-linux-android/release/libbitcoinz_mobile.so ]; then
    cp target/aarch64-linux-android/release/libbitcoinz_mobile.so ../flutter_app/android/app/src/main/jniLibs/arm64-v8a/
    echo "✅ ARM64 library copied"
else
    echo "❌ ARM64 library not found"
fi

# Build for ARM32
echo "📱 Building for ARM32..."
cargo build --target armv7-linux-androideabi --release
if [ -f target/armv7-linux-androideabi/release/libbitcoinz_mobile.so ]; then
    cp target/armv7-linux-androideabi/release/libbitcoinz_mobile.so ../flutter_app/android/app/src/main/jniLibs/armeabi-v7a/
    echo "✅ ARM32 library copied"
else
    echo "❌ ARM32 library not found"
fi

# Build for x86_64 (emulators)
echo "🖥️  Building for x86_64..."
cargo build --target x86_64-linux-android --release
if [ -f target/x86_64-linux-android/release/libbitcoinz_mobile.so ]; then
    cp target/x86_64-linux-android/release/libbitcoinz_mobile.so ../flutter_app/android/app/src/main/jniLibs/x86_64/
    echo "✅ x86_64 library copied"
else
    echo "❌ x86_64 library not found"
fi

cd ..

echo "✅ Build complete! Libraries should be in flutter_app/android/app/src/main/jniLibs/"
ls -la flutter_app/android/app/src/main/jniLibs/*/