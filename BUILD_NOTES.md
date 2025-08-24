# BitcoinZ Mobile Wallet - Build Notes

## Android Build Process

### Prerequisites
1. Flutter SDK installed and in PATH
2. Android SDK and NDK installed
3. Rust toolchain installed with Android targets

### Important: Rust Library Setup for Android

The Android app requires the Rust native library to be properly placed in the jniLibs directory.

#### 1. Build the Rust library for Android (if not already built):
```bash
# From project root
./scripts/build_rust_android.sh
```

This creates: `rust/target/aarch64-linux-android/release/libbitcoinz_wallet_rust.so`

#### 2. Copy the library to Android jniLibs:
```bash
# Create the jniLibs directory if it doesn't exist
mkdir -p flutter_app/android/app/src/main/jniLibs/arm64-v8a

# Copy the Rust library
cp rust/target/aarch64-linux-android/release/libbitcoinz_wallet_rust.so \
   flutter_app/android/app/src/main/jniLibs/arm64-v8a/
```

**CRITICAL**: Without this step, the app will build but transactions won't load on Android!

### Build Commands

#### Debug Build (for testing):
```bash
cd flutter_app
flutter build apk --debug
```

#### Release Build (for production):
```bash
cd flutter_app
flutter build apk --release
```

#### Build App Bundle (for Play Store):
```bash
cd flutter_app
flutter build appbundle --release
```

### Output Locations
- Debug APK: `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `flutter_app/build/app/outputs/bundle/release/app-release.aab`

### Installation

#### Install on connected device/emulator:
```bash
# Debug APK
adb install flutter_app/build/app/outputs/flutter-apk/app-debug.apk

# Release APK
adb install flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

#### Replace existing installation:
```bash
adb install -r flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

## iOS Build Process

### Prerequisites
1. macOS with Xcode installed
2. Valid Apple Developer account (for device testing)
3. CocoaPods installed

### Build the Rust library for iOS:
```bash
# From project root
./scripts/build_rust_ios.sh
```

### Build Commands

#### Debug Build:
```bash
cd flutter_app
flutter build ios --debug
```

#### Release Build:
```bash
cd flutter_app
flutter build ios --release
```

#### Open in Xcode:
```bash
cd flutter_app/ios
open Runner.xcworkspace
```

## Common Issues and Solutions

### Issue: Transactions not loading on Android
**Solution**: Ensure the Rust library is copied to jniLibs directory (see Android setup above)

### Issue: Build fails with "source value 8 is obsolete"
**Solution**: This is a warning and can be ignored. The build should still complete.

### Issue: Rust commands timing out on Android
**Cause**: The Rust FFI bridge is slow on Android, especially during initial sync
**Workaround**: Timeouts have been added to prevent hanging. The app will show empty transactions until sync completes.

### Issue: "No wallet" error on app restart (Android)
**Solution**: This has been fixed by creating the wallet model immediately with cached data

## Testing Checklist

Before releasing, test these scenarios:

### Android
- [ ] App installs and launches
- [ ] Wallet creation works
- [ ] Wallet restoration from seed phrase works
- [ ] Balance displays correctly (may show 0 initially)
- [ ] Transactions load (may be slow/timeout initially)
- [ ] App maintains wallet after restart
- [ ] Send/Receive addresses display correctly

### iOS
- [ ] App installs and launches
- [ ] Wallet creation works
- [ ] Wallet restoration works
- [ ] Balance and transactions display
- [ ] App maintains wallet after restart

## Performance Notes

- The Rust FFI bridge is slower on Android than iOS/macOS
- Initial sync can take 10-30 seconds on Android
- Timeouts are set to 10 seconds for balance, 15 seconds for sync
- Transactions may not load immediately on Android due to performance issues

## Build Automation

For automated builds, create a script that:
1. Builds the Rust library for the target platform
2. Copies libraries to correct locations
3. Runs Flutter build command
4. Optionally signs the APK/IPA

Example automation script is available in `scripts/build_all.sh`