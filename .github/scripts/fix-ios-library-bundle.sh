#!/bin/bash
set -e

# Fix iOS library bundling - ensure Rust libraries are linked
echo "🍎 Fixing iOS library bundling..."

# For iOS, we need to ensure the static library is properly linked
# The library should be in ios/Frameworks/

if [ ! -f "ios/Frameworks/libbitcoinz_wallet_rust.a" ]; then
    echo "❌ iOS library not found in ios/Frameworks/"
    exit 1
fi

echo "📦 Found iOS library: ios/Frameworks/libbitcoinz_wallet_rust.a"

# Get library size
LIBRARY_SIZE=$(ls -lh "ios/Frameworks/libbitcoinz_wallet_rust.a" | awk '{print $5}')
echo "📏 Library size: $LIBRARY_SIZE"

# For iOS, the static library needs to be linked during build
# This is typically handled by the Xcode project settings
# We'll verify it's accessible

echo "✅ iOS library is in place for linking"

# Note: The actual linking happens during the Xcode build process
# The library must be in ios/Frameworks/ before running flutter build ios