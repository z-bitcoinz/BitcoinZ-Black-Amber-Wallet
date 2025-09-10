#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - Rust Targets Setup Script
# Installs all required Rust targets for cross-platform compilation

echo "🦀 Setting up Rust targets for multi-platform builds..."

# Check if Rust is installed
if ! command -v rustup &> /dev/null; then
    echo "❌ Rust is not installed. Please install Rust first:"
    echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

echo "📋 Current Rust version:"
rustc --version
rustup --version

echo "📱 Installing mobile targets..."

# Android targets
echo "🤖 Installing Android targets..."
rustup target add aarch64-linux-android      # ARM64 Android
rustup target add armv7-linux-androideabi    # ARMv7 Android
rustup target add x86_64-linux-android       # x86_64 Android Emulator
rustup target add i686-linux-android         # x86 Android Emulator

# iOS targets (only install on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Installing iOS targets..."
    rustup target add aarch64-apple-ios          # iOS devices (ARM64)
    rustup target add x86_64-apple-ios           # iOS Simulator (Intel)
    rustup target add aarch64-apple-ios-sim      # iOS Simulator (Apple Silicon)
    
    echo "🖥️ Installing macOS targets..."
    rustup target add x86_64-apple-darwin        # Intel macOS
    rustup target add aarch64-apple-darwin       # Apple Silicon macOS
else
    echo "⚠️  iOS and macOS targets skipped (not on macOS)"
fi

# Linux target (install on Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Installing Linux targets..."
    rustup target add x86_64-unknown-linux-gnu
else
    echo "ℹ️  Linux target may already be default"
fi

# Windows targets (install on Windows)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "🪟 Installing Windows targets..."
    rustup target add x86_64-pc-windows-msvc
else
    echo "ℹ️  Windows target skipped (not on Windows)"
fi

echo "🔧 Installing additional tools..."

# Install cargo-lipo for iOS/macOS universal binaries (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v cargo-lipo &> /dev/null; then
        echo "📦 Installing cargo-lipo..."
        cargo install cargo-lipo
    else
        echo "✅ cargo-lipo already installed"
    fi
fi

# Install cbindgen for C header generation
if ! command -v cbindgen &> /dev/null; then
    echo "📦 Installing cbindgen..."
    cargo install cbindgen
else
    echo "✅ cbindgen already installed"
fi

echo "📋 Installed targets:"
rustup target list --installed

echo "🎉 Rust targets setup completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Run platform-specific build scripts:"
echo "      - ./build-rust-android.sh"
echo "      - ./build-rust-ios.sh (macOS only)"
echo "      - ./build-rust-macos.sh (macOS only)"
echo "      - ./build-rust-linux.sh"
echo "      - ./build-rust-windows.bat (Windows only)"
echo ""
echo "   2. Or use GitHub Actions workflow for automated builds"