#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - Build and Run Script
# This script builds the Rust libraries and runs the Flutter app

echo "🚀 Building BitcoinZ Mobile Wallet..."

# Check if we're in the right directory
if [ ! -f "rust_core/Cargo.toml" ] || [ ! -f "flutter_app/pubspec.yaml" ]; then
    echo "❌ Error: This script must be run from the bitcoinz-mobile-wallet root directory"
    exit 1
fi

# Parse command line arguments
PLATFORM=${1:-"all"}
MODE=${2:-"debug"}

echo "📋 Build Configuration:"
echo "   Platform: $PLATFORM"
echo "   Mode: $MODE"
echo ""

# Function to build Rust for Android
build_android() {
    echo "🤖 Building for Android..."
    
    # Check if Android NDK is set
    if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$NDK_HOME" ]; then
        echo "⚠️  Warning: Android NDK not found. Skipping Android Rust build."
        echo "   Set ANDROID_NDK_HOME to enable Android builds"
    else
        ./scripts/build_rust_android.sh
    fi
}

# Function to build Rust for iOS
build_ios() {
    echo "🍎 Building for iOS..."
    
    # Check if on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "⚠️  Warning: iOS builds require macOS. Skipping iOS build."
    else
        ./scripts/build_rust_ios.sh
    fi
}

# Function to build Rust for macOS
build_macos() {
    echo "🖥️  Building for macOS..."
    
    # Check if on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "⚠️  Warning: macOS builds require macOS. Skipping macOS build."
    else
        ./scripts/build_rust_macos.sh
    fi
}

# Build Rust libraries based on platform
case $PLATFORM in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    macos)
        build_macos
        ;;
    all)
        echo "📦 Building for all platforms..."
        build_android
        build_ios
        build_macos
        ;;
    *)
        echo "❌ Error: Unknown platform '$PLATFORM'"
        echo "   Valid options: android, ios, macos, all"
        exit 1
        ;;
esac

echo ""
echo "✅ Rust libraries built successfully!"
echo ""

# Navigate to Flutter app directory
cd flutter_app

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Generate code if needed
if [ -f "build.yaml" ]; then
    echo "🔧 Running code generation..."
    dart run build_runner build --delete-conflicting-outputs
fi

echo ""
echo "🎯 Ready to run the app!"
echo ""
echo "📋 Run commands:"
echo ""

# Show run commands based on platform
if [ "$PLATFORM" == "android" ] || [ "$PLATFORM" == "all" ]; then
    echo "   🤖 Android:"
    echo "      flutter run                    # Run on connected device/emulator"
    echo "      flutter build apk --$MODE      # Build APK"
    echo "      flutter build appbundle --$MODE # Build App Bundle"
    echo ""
fi

if [ "$PLATFORM" == "ios" ] || [ "$PLATFORM" == "all" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   🍎 iOS:"
        echo "      flutter run                    # Run on connected device/simulator"
        echo "      flutter build ios --$MODE      # Build for iOS"
        echo "      flutter build ipa --$MODE      # Build IPA for App Store"
        echo ""
    fi
fi

if [ "$PLATFORM" == "macos" ] || [ "$PLATFORM" == "all" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   🖥️  macOS:"
        echo "      flutter run -d macos           # Run on macOS"
        echo "      flutter build macos --$MODE    # Build macOS app"
        echo ""
    fi
fi

echo "💡 Tips:"
echo "   • Use 'flutter devices' to see available devices"
echo "   • Use 'flutter doctor' to check your environment"
echo "   • Add '--release' flag for production builds"
echo ""

# Optionally run the app immediately
read -p "🚀 Do you want to run the app now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting Flutter app..."
    flutter run
fi