#!/bin/bash
set -e

# BitcoinZ Desktop Wallet - macOS Build Script
# This script compiles the Rust core library for macOS desktop

echo "🔧 Building BitcoinZ Desktop Wallet for macOS..."

# Check if we're in the right directory
if [ ! -f "rust_core/Cargo.toml" ]; then
    echo "❌ Error: This script must be run from the bitcoinz-mobile-wallet root directory"
    exit 1
fi

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script requires macOS"
    exit 1
fi

# macOS targets to build for
MACOS_TARGETS=(
    "x86_64-apple-darwin"          # Intel Macs
    "aarch64-apple-darwin"         # Apple Silicon Macs
)

# Create output directories
mkdir -p macos_app/macos/Runner/Frameworks

cd rust_core

echo "📋 Installing Rust targets for macOS..."
for target in "${MACOS_TARGETS[@]}"; do
    rustup target add $target
done

echo "🚀 Building for macOS targets..."

# Build for Intel Macs (x86_64)
echo "🖥️  Building for Intel Macs (x86_64-apple-darwin)..."
cargo build --target x86_64-apple-darwin --release

# Build for Apple Silicon Macs (ARM64)
echo "💻 Building for Apple Silicon Macs (aarch64-apple-darwin)..."
cargo build --target aarch64-apple-darwin --release

echo "🔗 Creating universal library..."

# Create universal library using lipo
lipo -create \
    target/x86_64-apple-darwin/release/libbitcoinz_mobile.dylib \
    target/aarch64-apple-darwin/release/libbitcoinz_mobile.dylib \
    -output target/libbitcoinz_mobile_universal.dylib

# Also create static library version
lipo -create \
    target/x86_64-apple-darwin/release/libbitcoinz_mobile.a \
    target/aarch64-apple-darwin/release/libbitcoinz_mobile.a \
    -output target/libbitcoinz_mobile_universal.a

# Copy to Flutter macOS directory
cp target/libbitcoinz_mobile_universal.dylib ../macos_app/macos/Runner/Frameworks/libbitcoinz_mobile.dylib
cp target/libbitcoinz_mobile_universal.a ../macos_app/macos/Runner/Frameworks/libbitcoinz_mobile.a

# Create C header file for macOS
cat > ../macos_app/macos/Runner/Frameworks/bitcoinz_mobile.h << 'EOF'
#ifndef BITCOINZ_MOBILE_H
#define BITCOINZ_MOBILE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// BitcoinZ Desktop Wallet C Interface

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

#ifdef __cplusplus
}
#endif

#endif /* BITCOINZ_MOBILE_H */
EOF

cd ..

echo "✅ macOS build completed successfully!"
echo "📦 Universal library created: macos_app/macos/Runner/Frameworks/libbitcoinz_mobile.dylib"
echo "📦 Static library created: macos_app/macos/Runner/Frameworks/libbitcoinz_mobile.a"
echo "📦 C header created: macos_app/macos/Runner/Frameworks/bitcoinz_mobile.h"
echo ""
echo "📋 Next steps:"
echo "   1. cd macos_app"
echo "   2. flutter build macos"
echo "   or"
echo "   flutter run -d macos"
echo ""
echo "💡 Note: Make sure to configure Xcode signing if building for distribution"