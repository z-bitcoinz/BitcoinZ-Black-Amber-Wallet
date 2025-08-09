# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BitcoinZ Mobile Light Wallet - A secure, privacy-focused cross-platform mobile wallet built with Flutter frontend and Rust FFI backend for maximum performance and security.

## Essential Commands

### Build Commands
```bash
# Initial setup (required once)
./scripts/setup_environment.sh

# Platform-specific Rust builds (required before Flutter builds)
./scripts/build_rust_android.sh    # For Android
./scripts/build_rust_ios.sh        # For iOS (macOS only)
./scripts/build_rust_macos.sh      # For macOS

# Flutter builds
flutter build apk                  # Android APK
flutter build appbundle           # Android App Bundle
flutter build ios                # iOS (requires macOS)
flutter build macos --debug      # macOS debug build

# Development mode
flutter run                      # Run on connected device/emulator
```

### Test Commands
```bash
# Rust core tests
cd rust_core && cargo test

# Flutter tests
cd flutter_app && flutter test

# Flutter analysis/linting
cd flutter_app && flutter analyze
```

## Architecture Overview

### Hybrid Flutter + Rust FFI Architecture

The app uses a two-layer architecture with Flutter handling UI/UX and Rust providing cryptographic operations and blockchain interaction:

1. **Flutter Layer** (`/flutter_app/`):
   - UI/UX with Material 3 design
   - State management via Provider pattern
   - FFI service layer for Rust communication
   - Secure storage for sensitive data

2. **Rust Core** (`/rust_core/`):
   - All cryptographic operations
   - Direct blockchain communication via lightwalletd protocol
   - Memory-safe FFI exports (40+ functions)
   - Zero-knowledge proof generation

### Key Architectural Decisions

- **FFI Bridge**: Direct Rust integration for performance-critical operations. All crypto operations happen in Rust for security.
- **State Management**: Provider pattern with ChangeNotifier for reactive UI updates
- **Storage**: Flutter Secure Storage for sensitive data, SharedPreferences for settings
- **Network**: Direct connection to BitcoinZ lightwalletd servers (default: `https://lightd.btcz.rocks:9067`)

### Critical Files for Understanding the System

1. **`/rust_core/src/lib.rs`**: Main FFI exports - defines the contract between Flutter and Rust
2. **`/flutter_app/lib/services/rust_ffi_service.dart`**: Flutter-side FFI integration
3. **`/flutter_app/lib/providers/wallet_provider.dart`**: Core wallet state management
4. **`/flutter_app/lib/models/`**: Data models with JSON serialization
5. **`/rust_core/src/mobile_wallet.rs`**: Core wallet operations implementation

### FFI Function Patterns

When adding new FFI functions:
1. Define in `/rust_core/src/lib.rs` with `#[no_mangle]` and `extern "C"`
2. Add corresponding Dart binding in `/flutter_app/lib/services/rust_ffi_service.dart`
3. Use CString for string parameters, return JSON strings for complex data
4. Always handle errors with Result<String, String> pattern

### Development Workflow

1. **Rust changes**: Modify Rust code → Run platform build script → Test with `cargo test`
2. **Flutter changes**: Standard Flutter development → Hot reload works for UI
3. **FFI changes**: Requires rebuilding Rust library and Flutter restart

### Platform-Specific Notes

- **Android**: Requires NDK setup, builds for arm64-v8a and armeabi-v7a
- **iOS**: Requires macOS with Xcode, builds universal binary
- **macOS**: Direct native build support
- **Linux/Windows**: Desktop support exists but not primary focus

### Security Considerations

- All private keys and sensitive operations stay in Rust memory
- Use secure storage APIs for persisting sensitive data
- Biometric authentication integrated via local_auth
- Auto-lock feature with configurable timeout
- Never log sensitive information

### Testing Strategy

- Rust unit tests for cryptographic operations
- Flutter widget tests for UI components
- Integration tests should verify FFI bridge functionality
- Always test address generation and transaction signing thoroughly