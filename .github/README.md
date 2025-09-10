# 🚀 GitHub Actions CI/CD Pipeline

## Overview

This repository uses GitHub Actions to automatically build BitcoinZ Black Amber wallet for all supported platforms:

- 🤖 **Android**: APK + App Bundle (ARM64, ARMv7, x86, x86_64)
- 🍎 **iOS**: Universal app (device + simulator)
- 🖥️ **macOS**: Universal app (Intel + Apple Silicon)
- 🐧 **Linux**: x86_64 application bundle
- 🪟 **Windows**: x86_64 application bundle

## Workflow Structure

### Main Workflow: `build-multiplatform.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`
- Release publications

**Jobs:**
1. **build-android**: Builds Android APK and App Bundle
2. **build-ios**: Builds iOS app (unsigned)
3. **build-macos**: Builds macOS app bundle
4. **build-linux**: Builds Linux application
5. **build-windows**: Builds Windows application
6. **create-release**: Creates GitHub release with all artifacts

## Architecture

### Rust FFI Backend
Each platform requires native Rust libraries compiled for specific targets:

| Platform | Rust Targets | Output Libraries |
|----------|--------------|------------------|
| Android | `aarch64-linux-android`<br>`armv7-linux-androideabi`<br>`x86_64-linux-android`<br>`i686-linux-android` | `libbitcoinz_wallet_rust.so` |
| iOS | `aarch64-apple-ios`<br>`x86_64-apple-ios`<br>`aarch64-apple-ios-sim` | `libbitcoinz_wallet_rust.a` |
| macOS | `x86_64-apple-darwin`<br>`aarch64-apple-darwin` | `libbitcoinz_wallet_rust.a`<br>`libbitcoinz_wallet_rust.dylib` |
| Linux | `x86_64-unknown-linux-gnu` | `libbitcoinz_wallet_rust.so` |
| Windows | `x86_64-pc-windows-msvc` | `bitcoinz_wallet_rust.dll` |

### Build Process

1. **Rust Compilation**: Platform-specific scripts compile Rust libraries
2. **Flutter Rust Bridge**: Generates Dart bindings automatically
3. **Flutter Build**: Compiles Flutter app with native libraries
4. **Packaging**: Creates distribution-ready packages

## Build Scripts

### Platform-Specific Scripts

- **`scripts/build-rust-android.sh`**: Builds Android native libraries
- **`scripts/build-rust-ios.sh`**: Builds iOS universal library
- **`scripts/build-rust-macos.sh`**: Builds macOS universal library
- **`scripts/build-rust-linux.sh`**: Builds Linux library
- **`scripts/build-rust-windows.bat`**: Builds Windows library
- **`scripts/setup-rust-targets.sh`**: Installs all required Rust targets

### Local Development

```bash
# Setup Rust targets (one-time)
./.github/scripts/setup-rust-targets.sh

# Build for specific platform
cd flutter_app
./.github/scripts/build-rust-android.sh
flutter build apk --release

# Or build for current platform
flutter run -d macos  # macOS
flutter run -d linux  # Linux  
flutter run -d windows # Windows
```

## Performance Optimizations

### Caching Strategy

The workflow uses aggressive caching to reduce build times:

- **Rust Dependencies**: `~/.cargo/registry`, `~/.cargo/git`, `rust/target`
- **Flutter Dependencies**: `~/.pub-cache`, `.dart_tool`
- **Platform Tools**: Android SDK, Xcode, etc.

### Parallel Builds

All platform builds run simultaneously, reducing total build time from ~2 hours sequential to ~25 minutes parallel.

### Build Optimizations

- **Rust Release Mode**: Maximum optimizations with LTO
- **Flutter Release**: Optimized for size and performance
- **Target Stripping**: Debug symbols removed for smaller binaries

## Security Features

### Code Signing Support

The workflow supports code signing through repository secrets:

**iOS/macOS Signing:**
```yaml
secrets:
  IOS_CERTIFICATE_BASE64: # Base64 encoded .p12 certificate
  IOS_CERTIFICATE_PASSWORD: # Certificate password
  IOS_PROVISIONING_PROFILE: # Base64 encoded provisioning profile
  MACOS_CERTIFICATE_BASE64: # macOS signing certificate
  MACOS_CERTIFICATE_PASSWORD: # Certificate password
```

**Android Signing:**
```yaml
secrets:
  ANDROID_KEYSTORE_BASE64: # Base64 encoded keystore
  ANDROID_KEYSTORE_PASSWORD: # Keystore password
  ANDROID_KEY_ALIAS: # Key alias
  ANDROID_KEY_PASSWORD: # Key password
```

### Security Best Practices

- All secrets are encrypted and only available during builds
- Native libraries are compiled with security flags
- Release builds use production certificates
- No sensitive data is logged or cached

## Artifacts & Releases

### Build Artifacts

Each successful build uploads platform-specific artifacts:

- **Android**: `android-apk` (APK files + App Bundle)
- **iOS**: `ios-app` (Runner.app bundle)
- **macOS**: `macos-app` (ZIP archive)
- **Linux**: `linux-app` (tar.gz archive)
- **Windows**: `windows-app` (ZIP archive)

### Automatic Releases

When a release is published on GitHub:

1. All platforms are built automatically
2. Artifacts are attached to the release
3. Release notes are generated with download links
4. Distribution packages are ready for users

## Troubleshooting

### Common Issues

**Android NDK not found:**
```
❌ ANDROID_NDK_HOME not set!
```
*Solution: The workflow automatically sets up Android NDK r26d*

**iOS signing fails:**
```
❌ Code signing failed
```
*Solution: Add proper signing certificates to repository secrets*

**Rust target missing:**
```
❌ Target 'aarch64-apple-ios' not found
```
*Solution: Run `setup-rust-targets.sh` or use the workflow*

### Debug Builds

To debug build issues locally:

```bash
# Enable verbose logging
export RUST_LOG=debug
export FLUTTER_LOGS=debug

# Run specific build script
./.github/scripts/build-rust-android.sh
```

### Performance Analysis

Build times by platform (approximate):

- **Android**: ~8-12 minutes
- **iOS**: ~10-15 minutes
- **macOS**: ~8-12 minutes
- **Linux**: ~6-10 minutes  
- **Windows**: ~8-12 minutes

**Total parallel build time**: ~15-25 minutes

## Contributing

When modifying the build pipeline:

1. Test changes locally with the build scripts
2. Update this documentation
3. Verify all platform builds still work
4. Consider impact on build time and artifact size

For questions or issues with the CI/CD pipeline, please open an issue with the `ci/cd` label.