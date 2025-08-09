#!/bin/bash
set -e

# BitcoinZ Mobile Wallet - iOS Build Script
# This script compiles the Rust core library for iOS targets

echo "🔧 Building BitcoinZ Mobile Wallet for iOS..."

# Check if we're in the right directory
if [ ! -f "rust_core/Cargo.toml" ]; then
    echo "❌ Error: This script must be run from the bitcoinz-mobile-wallet root directory"
    exit 1
fi

# Check if we're on macOS (required for iOS development)
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: iOS builds require macOS"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# iOS targets to build for
IOS_TARGETS=(
    "aarch64-apple-ios"        # iOS devices (iPhone/iPad)
    "x86_64-apple-ios"         # iOS Simulator (Intel Macs)
    "aarch64-apple-ios-sim"    # iOS Simulator (Apple Silicon Macs)
)

# Create output directories
mkdir -p flutter_app/ios/Frameworks
mkdir -p flutter_app/ios/Runner/Frameworks

cd rust_core

echo "📋 Installing Rust targets for iOS..."
for target in "${IOS_TARGETS[@]}"; do
    rustup target add $target
done

echo "🚀 Building for iOS targets..."

# Build for iOS devices (ARM64)
echo "📱 Building for iOS devices (aarch64-apple-ios)..."
cargo build --target aarch64-apple-ios --release

# Build for iOS Simulator (x86_64 - Intel Macs)
echo "🖥️  Building for iOS Simulator x86_64 (x86_64-apple-ios)..."
cargo build --target x86_64-apple-ios --release

# Build for iOS Simulator (ARM64 - Apple Silicon Macs)
echo "🖥️  Building for iOS Simulator ARM64 (aarch64-apple-ios-sim)..."
cargo build --target aarch64-apple-ios-sim --release

echo "🔗 Creating universal libraries..."

# Create universal library for simulators
lipo -create \
    target/x86_64-apple-ios/release/libbitcoinz_mobile.a \
    target/aarch64-apple-ios-sim/release/libbitcoinz_mobile.a \
    -output target/libbitcoinz_mobile_sim.a

# Copy device library
cp target/aarch64-apple-ios/release/libbitcoinz_mobile.a target/libbitcoinz_mobile_device.a

# Create XCFramework (recommended for modern iOS development)
echo "📦 Creating XCFramework..."

# Clean any existing XCFramework
rm -rf target/BitcoinZMobile.xcframework

xcodebuild -create-xcframework \
    -library target/libbitcoinz_mobile_device.a \
    -library target/libbitcoinz_mobile_sim.a \
    -output target/BitcoinZMobile.xcframework

# Copy to Flutter iOS directory
cp -R target/BitcoinZMobile.xcframework ../flutter_app/ios/Frameworks/

# Also copy individual libraries for compatibility
cp target/libbitcoinz_mobile_device.a ../flutter_app/ios/Runner/Frameworks/libbitcoinz_mobile.a
cp target/libbitcoinz_mobile_sim.a ../flutter_app/ios/Runner/Frameworks/libbitcoinz_mobile_sim.a

# Create module map for C headers (if needed)
mkdir -p ../flutter_app/ios/Runner/Frameworks/BitcoinZMobile.framework/Headers
mkdir -p ../flutter_app/ios/Runner/Frameworks/BitcoinZMobile.framework/Modules

cat > ../flutter_app/ios/Runner/Frameworks/BitcoinZMobile.framework/Modules/module.modulemap << EOF
framework module BitcoinZMobile {
    header "bitcoinz_mobile.h"
    export *
}
EOF

# Create a basic header file (will need to be expanded with actual C declarations)
cat > ../flutter_app/ios/Runner/Frameworks/BitcoinZMobile.framework/Headers/bitcoinz_mobile.h << EOF
#ifndef BITCOINZ_MOBILE_H
#define BITCOINZ_MOBILE_H

#include <stdint.h>

// BitcoinZ Mobile Wallet C Interface

// Initialize wallet
char* bitcoinz_init(const char* server_url);

// Wallet management
char* bitcoinz_create_wallet(const char* seed_phrase);
char* bitcoinz_restore_wallet(const char* seed_phrase, uint32_t birthday_height);

// Balance and addresses
char* bitcoinz_get_balance(void);
char* bitcoinz_get_addresses(void);
char* bitcoinz_new_address(const char* address_type);

// Synchronization
char* bitcoinz_sync(void);
char* bitcoinz_sync_status(void);

// Transactions
char* bitcoinz_send_transaction(const char* to_address, uint64_t amount_zatoshis, const char* memo);
char* bitcoinz_get_transactions(void);

// Message encryption
char* bitcoinz_encrypt_message(const char* z_address, const char* message);
char* bitcoinz_decrypt_message(const char* encrypted_data);

// Cleanup
void bitcoinz_free_string(char* ptr);
char* bitcoinz_destroy(void);

#endif /* BITCOINZ_MOBILE_H */
EOF

cd ..

echo "✅ iOS build completed successfully!"
echo "📦 XCFramework created: flutter_app/ios/Frameworks/BitcoinZMobile.xcframework"
echo "📦 Static libraries copied to flutter_app/ios/Runner/Frameworks/"
echo ""
echo "📋 Next steps:"
echo "   1. Open flutter_app/ios/Runner.xcworkspace in Xcode"
echo "   2. Add BitcoinZMobile.xcframework to your project"
echo "   3. cd flutter_app && flutter build ios"
echo ""
echo "💡 Note: You may need to configure code signing in Xcode before building"