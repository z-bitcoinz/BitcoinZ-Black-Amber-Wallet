#!/bin/bash
set -e

# Fix Linux library bundling - ensure Rust libraries are included in the bundle
echo "🐧 Fixing Linux library bundling..."

# After building the Linux app, we need to ensure the Rust library is in the bundle
BUNDLE_PATH="build/linux/x64/release/bundle"
LIB_PATH="$BUNDLE_PATH/lib"

if [ ! -d "$BUNDLE_PATH" ]; then
    echo "❌ Bundle not found at $BUNDLE_PATH"
    exit 1
fi

echo "📦 Found bundle at: $BUNDLE_PATH"

# Create lib directory if it doesn't exist
mkdir -p "$LIB_PATH"

# Copy the Rust library to the bundle's lib directory
if [ -f "linux/libbitcoinz_wallet_rust.so" ]; then
    echo "📋 Copying Rust library to bundle..."
    cp "linux/libbitcoinz_wallet_rust.so" "$LIB_PATH/"
    echo "✅ Copied libbitcoinz_wallet_rust.so to bundle"
elif [ -f "build/native_assets/linux/libbitcoinz_wallet_rust.so" ]; then
    echo "📋 Copying Rust library from native_assets to bundle..."
    cp "build/native_assets/linux/libbitcoinz_wallet_rust.so" "$LIB_PATH/"
    echo "✅ Copied libbitcoinz_wallet_rust.so to bundle"
else
    echo "❌ Rust library not found!"
    echo "Checked:"
    echo "  - linux/libbitcoinz_wallet_rust.so"
    echo "  - build/native_assets/linux/libbitcoinz_wallet_rust.so"
    exit 1
fi

# Set proper permissions
chmod 755 "$LIB_PATH/libbitcoinz_wallet_rust.so"

# Verify the library is in the bundle
echo "📊 Bundle lib contents:"
ls -lh "$LIB_PATH"/*.so 2>/dev/null || echo "No .so files found"

# Check total bundle size
echo "📏 Total bundle size:"
du -sh "$BUNDLE_PATH"

# Create an LD_LIBRARY_PATH script for the executable
RUNNER_SCRIPT="$BUNDLE_PATH/flutter_app.sh"
if [ -f "$BUNDLE_PATH/flutter_app" ]; then
    echo "📝 Creating runner script..."
    cat > "$RUNNER_SCRIPT" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:$LD_LIBRARY_PATH"
exec "$SCRIPT_DIR/flutter_app" "$@"
EOF
    chmod +x "$RUNNER_SCRIPT"
    echo "✅ Created runner script to ensure library loading"
fi

echo "✅ Linux library bundling fix complete"