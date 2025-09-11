#!/bin/bash
set -e

# Setup native assets directories for Flutter Rust Bridge
# This ensures Rust libraries are in the correct locations for bundling

echo "🔧 Setting up native assets for Flutter build..."

# Detect platform
PLATFORM=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
fi

echo "📦 Platform detected: $PLATFORM"

# Linux native assets setup
if [ "$PLATFORM" == "linux" ] || [ -d "linux" ]; then
    echo "🐧 Setting up Linux native assets..."
    
    # Create native_assets directory for CMake
    mkdir -p build/native_assets/linux
    
    # Copy library from linux directory if it exists
    if [ -f "linux/libbitcoinz_wallet_rust.so" ]; then
        cp linux/libbitcoinz_wallet_rust.so build/native_assets/linux/
        echo "✅ Copied Linux library to native_assets"
    else
        echo "⚠️  Linux library not found in linux/"
    fi
    
    # Also check rust target directory
    if [ -f "rust/target/x86_64-unknown-linux-gnu/release/libbitcoinz_wallet_rust.so" ]; then
        cp rust/target/x86_64-unknown-linux-gnu/release/libbitcoinz_wallet_rust.so build/native_assets/linux/
        echo "✅ Copied Linux library from Rust target to native_assets"
    fi
fi

# Windows native assets setup
if [ "$PLATFORM" == "windows" ] || [ -d "windows" ]; then
    echo "🪟 Setting up Windows native assets..."
    
    # Create native_assets directory
    mkdir -p build/native_assets/windows
    
    # Copy DLL from windows directory if it exists
    if [ -f "windows/bitcoinz_wallet_rust.dll" ]; then
        cp windows/bitcoinz_wallet_rust.dll build/native_assets/windows/
        echo "✅ Copied Windows DLL to native_assets"
    else
        echo "⚠️  Windows DLL not found in windows/"
    fi
    
    # Also check rust target directory
    if [ -f "rust/target/x86_64-pc-windows-msvc/release/bitcoinz_wallet_rust.dll" ]; then
        cp rust/target/x86_64-pc-windows-msvc/release/bitcoinz_wallet_rust.dll build/native_assets/windows/
        echo "✅ Copied Windows DLL from Rust target to native_assets"
    fi
fi

# macOS native assets setup
if [ "$PLATFORM" == "macos" ] || [ -d "macos" ]; then
    echo "🖥️  Setting up macOS native assets..."
    
    # Ensure Frameworks directory exists
    mkdir -p macos/Frameworks
    
    # Copy libraries from rust target if they exist
    if [ -f "rust/target/release/libbitcoinz_wallet_rust.dylib" ]; then
        cp rust/target/release/libbitcoinz_wallet_rust.dylib macos/Frameworks/
        echo "✅ Copied macOS dynamic library to Frameworks"
    fi
    
    if [ -f "rust/target/release/libbitcoinz_wallet_rust.a" ]; then
        cp rust/target/release/libbitcoinz_wallet_rust.a macos/Frameworks/
        echo "✅ Copied macOS static library to Frameworks"
    fi
fi

# iOS native assets setup (if on macOS)
if [ -d "ios" ]; then
    echo "🍎 Setting up iOS native assets..."
    
    # Ensure Frameworks directory exists
    mkdir -p ios/Frameworks
    
    # iOS libraries should already be in ios/Frameworks from build script
    if [ -f "ios/Frameworks/libbitcoinz_wallet_rust.a" ]; then
        echo "✅ iOS universal library found in Frameworks"
    else
        echo "⚠️  iOS library not found in ios/Frameworks/"
    fi
fi

# Android native assets (already handled by gradle)
if [ -d "android" ]; then
    echo "🤖 Checking Android native assets..."
    
    # Count Android libraries
    ANDROID_LIBS=$(find android/app/src/main/jniLibs -name "*.so" 2>/dev/null | wc -l)
    if [ "$ANDROID_LIBS" -gt 0 ]; then
        echo "✅ Found $ANDROID_LIBS Android native libraries"
    else
        echo "⚠️  No Android libraries found in jniLibs"
    fi
fi

echo "📊 Native assets setup summary:"
echo "----------------------------------------"

# Show what was set up
if [ -d "build/native_assets/linux" ]; then
    echo "Linux: $(ls -la build/native_assets/linux/*.so 2>/dev/null | wc -l) libraries"
fi

if [ -d "build/native_assets/windows" ]; then
    echo "Windows: $(ls -la build/native_assets/windows/*.dll 2>/dev/null | wc -l) libraries"
fi

if [ -d "macos/Frameworks" ]; then
    echo "macOS: $(ls -la macos/Frameworks/*.dylib macos/Frameworks/*.a 2>/dev/null | wc -l) libraries"
fi

if [ -d "ios/Frameworks" ]; then
    echo "iOS: $(ls -la ios/Frameworks/*.a 2>/dev/null | wc -l) libraries"
fi

if [ -d "android/app/src/main/jniLibs" ]; then
    echo "Android: $(find android/app/src/main/jniLibs -name "*.so" 2>/dev/null | wc -l) libraries"
fi

echo "----------------------------------------"
echo "✅ Native assets setup complete!"