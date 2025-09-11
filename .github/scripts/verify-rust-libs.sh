#!/bin/bash
set -e

# Verify that Rust libraries have been built and copied correctly
echo "🔍 Verifying Rust libraries..."

# Check Android libraries
if [ -d "android/app/src/main/jniLibs" ]; then
    echo "📱 Android libraries:"
    find android/app/src/main/jniLibs -name "*.so" -exec ls -lh {} \;
    ANDROID_LIBS=$(find android/app/src/main/jniLibs -name "*.so" | wc -l)
    if [ "$ANDROID_LIBS" -eq 0 ]; then
        echo "❌ No Android libraries found!"
        exit 1
    fi
    echo "✅ Found $ANDROID_LIBS Android libraries"
else
    echo "⚠️  Android jniLibs directory not found (OK if not building for Android)"
fi

# Check iOS libraries
if [ -d "ios/Frameworks" ]; then
    echo "🍎 iOS libraries:"
    ls -lh ios/Frameworks/*.a 2>/dev/null || echo "No iOS libraries found"
fi

# Check macOS libraries
if [ -d "macos/Frameworks" ]; then
    echo "🖥️  macOS libraries:"
    ls -lh macos/Frameworks/*.a 2>/dev/null || echo "No macOS static libraries found"
    ls -lh macos/Frameworks/*.dylib 2>/dev/null || echo "No macOS dynamic libraries found"
fi

# Check Linux libraries
if [ -d "linux" ]; then
    echo "🐧 Linux libraries:"
    ls -lh linux/*.so 2>/dev/null || echo "No Linux shared libraries found"
    ls -lh linux/*.a 2>/dev/null || echo "No Linux static libraries found"
fi

# Check Windows libraries
if [ -d "windows" ]; then
    echo "🪟 Windows libraries:"
    ls -lh windows/*.dll 2>/dev/null || echo "No Windows DLL found"
    ls -lh windows/*.lib 2>/dev/null || echo "No Windows LIB found"
fi

echo "✅ Library verification complete"