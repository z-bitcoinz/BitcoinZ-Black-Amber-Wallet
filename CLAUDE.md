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

# Flutter builds (from flutter_app directory)
cd flutter_app
flutter build apk                  # Android APK
flutter build appbundle           # Android App Bundle
flutter build ios                # iOS (requires macOS)
flutter build macos --debug      # macOS debug build

# Development mode
flutter run                      # Run on connected device/emulator
```

### Test Commands
```bash
# Rust library tests (Flutter Rust Bridge)
cd flutter_app/rust && cargo test

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

2. **Rust Library** (`/flutter_app/rust/`):
   - Flutter Rust Bridge integration (v2.11.1)
   - All cryptographic operations via zecwalletlitelib
   - Direct blockchain communication via lightwalletd protocol
   - Memory-safe FFI exports
   - Zero-knowledge proof generation

### Key Architectural Decisions

- **FFI Bridge**: Direct Rust integration for performance-critical operations. All crypto operations happen in Rust for security.
- **State Management**: Provider pattern with ChangeNotifier for reactive UI updates
- **Storage**: Flutter Secure Storage for sensitive data, SharedPreferences for settings
- **Network**: Direct connection to BitcoinZ lightwalletd servers (default: `https://lightd.btcz.rocks:9067`)

### Critical Files for Understanding the System

1. **`/flutter_app/rust/src/lib.rs`**: Main FFI exports via Flutter Rust Bridge
2. **`/flutter_app/lib/services/bitcoinz_rust_service.dart`**: Flutter-side Rust FFI integration
3. **`/flutter_app/lib/providers/wallet_provider.dart`**: Core wallet state management
4. **`/flutter_app/lib/models/`**: Data models with JSON serialization
5. **`/flutter_app/rust/zecwalletlitelib/`**: Core BitcoinZ wallet operations (from BitcoinZ Blue)
6. **`/flutter_app/lib/services/complete_bitcoinz_rpc_service.dart`**: Legacy RPC service (40+ methods)

### FFI Function Patterns

When adding new FFI functions:
1. Define in `/flutter_app/rust/src/lib.rs` using Flutter Rust Bridge annotations
2. Run `flutter_rust_bridge_codegen generate` to update Dart bindings
3. Use standard Rust types - Flutter Rust Bridge handles serialization
4. Always handle errors with Result<T, String> pattern
5. Update `/flutter_app/lib/services/bitcoinz_rust_service.dart` for high-level service calls

### Development Workflow

1. **Rust changes**: Modify code in `/flutter_app/rust/` → Run `flutter_rust_bridge_codegen generate` → Test with `cargo test`
2. **Flutter changes**: Standard Flutter development → Hot reload works for UI
3. **FFI changes**: Run codegen, rebuild Rust library, and restart Flutter app
4. **New FFI functions**: Define in Rust → Run codegen → Update Dart service layer

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

### Key Dependencies

- **Flutter Rust Bridge**: v2.11.1 for seamless Rust-Flutter integration
- **zecwalletlitelib**: Core wallet functionality ported from BitcoinZ Blue
- **Provider**: State management for reactive UI updates
- **flutter_secure_storage**: Secure storage for sensitive data (keys, seeds)
- **local_auth**: Biometric authentication support
- **mobile_scanner**: QR code scanning for addresses and URIs

### Testing Strategy

- Rust unit tests for cryptographic operations (`cd flutter_app/rust && cargo test`)
- Flutter widget tests for UI components (`cd flutter_app && flutter test`)
- Integration tests should verify FFI bridge functionality
- Always test address generation and transaction signing thoroughly
- Use `flutter analyze` for code quality checks