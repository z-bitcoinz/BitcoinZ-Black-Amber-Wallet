#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - Development Environment Setup
# This script sets up the development environment for building the mobile wallet

echo "🚀 Setting up BitcoinZ Mobile Wallet development environment..."

# Check operating system
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
fi

echo "🖥️  Detected OS: $OS"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install Rust
echo "🦀 Checking Rust installation..."
if ! command_exists rustc; then
    echo "📥 Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
else
    echo "✅ Rust is already installed"
    rustc --version
fi

# Update Rust to latest stable
echo "🔄 Updating Rust to latest stable..."
rustup update stable

# Check and install Flutter
echo "🐦 Checking Flutter installation..."
if ! command_exists flutter; then
    echo "📥 Flutter not found. Please install Flutter manually:"
    echo "   Visit: https://docs.flutter.dev/get-started/install"
    echo "   Or use package manager:"
    
    if [[ "$OS" == "macos" ]]; then
        echo "   brew install --cask flutter"
    elif [[ "$OS" == "linux" ]]; then
        echo "   snap install flutter --classic"
    fi
    
    echo ""
    echo "❌ Please install Flutter and run this script again"
    exit 1
else
    echo "✅ Flutter is already installed"
    flutter --version
fi

# Install Rust mobile targets
echo "📱 Installing Rust mobile targets..."

# Android targets
ANDROID_TARGETS=(
    "aarch64-linux-android"
    "armv7-linux-androideabi"
    "x86_64-linux-android"
    "i686-linux-android"
)

for target in "${ANDROID_TARGETS[@]}"; do
    echo "📥 Installing $target..."
    rustup target add $target
done

# iOS targets (only on macOS)
if [[ "$OS" == "macos" ]]; then
    echo "🍎 Installing iOS targets..."
    
    IOS_TARGETS=(
        "aarch64-apple-ios"
        "x86_64-apple-ios"
        "aarch64-apple-ios-sim"
    )
    
    for target in "${IOS_TARGETS[@]}"; do
        echo "📥 Installing $target..."
        rustup target add $target
    done
else
    echo "⚠️  iOS targets skipped (not on macOS)"
fi

# Install required tools
echo "🔧 Installing additional tools..."

# Install cargo-lipo for iOS universal libraries (macOS only)
if [[ "$OS" == "macos" ]]; then
    if ! command_exists cargo-lipo; then
        echo "📥 Installing cargo-lipo..."
        cargo install cargo-lipo
    else
        echo "✅ cargo-lipo already installed"
    fi
fi

# Install cbindgen for generating C headers
if ! command_exists cbindgen; then
    echo "📥 Installing cbindgen..."
    cargo install cbindgen
else
    echo "✅ cbindgen already installed"
fi

# Make build scripts executable
echo "🔐 Making build scripts executable..."
chmod +x scripts/build_rust_android.sh
chmod +x scripts/build_rust_ios.sh

# Verify Android development setup
echo "🤖 Checking Android development setup..."
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    echo "⚠️  Android SDK not found. Please set ANDROID_HOME or ANDROID_SDK_ROOT"
    echo "   Example: export ANDROID_HOME=~/Android/Sdk"
else
    echo "✅ Android SDK found"
fi

if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "⚠️  Android NDK not found. Please set ANDROID_NDK_HOME"
    echo "   Install NDK through Android Studio or download from:"
    echo "   https://developer.android.com/ndk/downloads"
else
    echo "✅ Android NDK found: $ANDROID_NDK_HOME"
fi

# Verify iOS development setup (macOS only)
if [[ "$OS" == "macos" ]]; then
    echo "🍎 Checking iOS development setup..."
    if ! command_exists xcodebuild; then
        echo "⚠️  Xcode not found. Please install Xcode from the App Store"
    else
        echo "✅ Xcode found"
        xcodebuild -version
    fi
else
    echo "⚠️  iOS development setup skipped (not on macOS)"
fi

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
if [ -d "flutter_app" ]; then
    cd flutter_app
    flutter pub get
    cd ..
else
    echo "⚠️  Flutter app directory not found. Will be created later."
fi

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p rust_core/target
mkdir -p flutter_app/android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64,x86}
mkdir -p flutter_app/ios/Frameworks
mkdir -p docs
mkdir -p logs

echo ""
echo "✅ Development environment setup completed!"
echo ""
echo "📋 Summary:"
echo "   🦀 Rust: $(rustc --version)"
echo "   🐦 Flutter: $(flutter --version | head -n 1)"
echo "   📱 Android targets: ${#ANDROID_TARGETS[@]} installed"

if [[ "$OS" == "macos" ]]; then
    echo "   🍎 iOS targets: 3 installed"
    echo "   🔨 Xcode: $(xcodebuild -version | head -n 1)"
fi

echo ""
echo "🚀 Ready to build BitcoinZ Mobile Wallet!"
echo ""
echo "📋 Next steps:"
echo "   1. ./scripts/build_rust_android.sh  # Build for Android"
if [[ "$OS" == "macos" ]]; then
    echo "   2. ./scripts/build_rust_ios.sh      # Build for iOS"
fi
echo "   3. cd flutter_app && flutter run    # Run Flutter app"
echo ""
echo "📚 Documentation:"
echo "   - Architecture: docs/ARCHITECTURE.md"
echo "   - Setup Guide: docs/SETUP.md" 
echo "   - FFI Reference: docs/FFI_REFERENCE.md"