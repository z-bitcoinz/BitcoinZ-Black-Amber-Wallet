# BitcoinZ Mobile Wallet

A secure, privacy-focused mobile wallet for BitcoinZ cryptocurrency built with Flutter and Rust.

## 🚀 Features

- **Native Performance**: Direct Rust integration via FFI for maximum performance
- **Full Privacy**: Light wallet design - no backend servers, direct blockchain connection
- **Cross-Platform**: Single codebase for iOS and Android
- **Shielded Transactions**: Full support for transparent and shielded addresses
- **Message Encryption**: Secure messaging with z-addresses
- **Biometric Security**: Fingerprint and Face ID authentication
- **Offline Capability**: View wallet and transaction history without internet

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                       │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐   │
│  │   UI Screens    │ │  State Mgmt     │ │   Services   │   │
│  │                 │ │  (Provider)     │ │   (FFI)      │   │
│  └─────────────────┘ └─────────────────┘ └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │ FFI
┌─────────────────────────────────────────────────────────────┐
│                  Rust Core Library                         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐   │
│  │ Mobile Wallet   │ │  BitcoinZ CLI   │ │   Crypto     │   │
│  │   Wrapper       │ │  Integration    │ │  Functions   │   │
│  └─────────────────┘ └─────────────────┘ └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────────────────┐
                    │  BitcoinZ Network   │
                    │   (lightwalletd)    │
                    └─────────────────────┘
```

## 📋 Prerequisites

- **Flutter**: 3.1.0 or higher
- **Rust**: 1.70 or higher
- **Android Studio**: For Android development
- **Xcode**: For iOS development (macOS only)
- **Android NDK**: For Android builds
- **BitcoinZ-Light-CLI**: Existing working CLI wallet

## 🛠️ Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bitcoinz-mobile-wallet
   ```

2. **Run environment setup**
   ```bash
   ./scripts/setup_environment.sh
   ```

3. **Install Flutter dependencies**
   ```bash
   cd flutter_app
   flutter pub get
   ```

## 🔨 Building

### Android
```bash
# Build Rust library for Android
./scripts/build_rust_android.sh

# Build Flutter app
cd flutter_app
flutter build apk
# or
flutter build appbundle
```

### iOS (macOS only)
```bash
# Build Rust library for iOS
./scripts/build_rust_ios.sh

# Build Flutter app
cd flutter_app
flutter build ios
```

## 🏃‍♂️ Running

### Development
```bash
cd flutter_app
flutter run
```

### Emulator/Simulator
```bash
# Android emulator
flutter run -d android

# iOS simulator
flutter run -d ios
```

## 📁 Project Structure

```
bitcoinz-mobile-wallet/
├── rust_core/                    # Rust FFI library
│   ├── src/
│   │   ├── lib.rs                # FFI exports
│   │   ├── mobile_wallet.rs      # Wallet operations
│   │   ├── ffi_bridge.rs         # FFI utilities
│   │   └── error_handling.rs     # Error types
│   └── Cargo.toml
├── flutter_app/                  # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart             # App entry point
│   │   ├── models/               # Data models
│   │   ├── services/             # Business logic
│   │   ├── providers/            # State management
│   │   ├── screens/              # UI screens
│   │   ├── widgets/              # Reusable components
│   │   └── utils/                # Utilities
│   └── pubspec.yaml
├── scripts/                      # Build automation
│   ├── setup_environment.sh
│   ├── build_rust_android.sh
│   └── build_rust_ios.sh
└── docs/                         # Documentation
```

## 🔧 Development Status

### ✅ Completed
- [x] Rust FFI core library structure
- [x] Flutter app foundation with modern architecture
- [x] Cross-compilation build scripts
- [x] Data models and validation
- [x] Native service integration
- [x] Professional UI theme and styling

### 🚧 In Progress
- [ ] Integration with BitcoinZ-Light-CLI libraries
- [ ] UI screens implementation
- [ ] Authentication and security services
- [ ] State management providers
- [ ] Testing and optimization

### 📅 Planned
- [ ] App store deployment
- [ ] Advanced features (address book, backup)
- [ ] Multi-language support
- [ ] Hardware wallet integration

## 🔒 Security Features

- **Local-only Processing**: All cryptographic operations happen on device
- **Secure Storage**: Encrypted local storage for sensitive data
- **Biometric Authentication**: Fingerprint and Face ID support
- **Auto-lock**: Automatic wallet locking after inactivity
- **Secure Memory**: Proper cleanup of sensitive data in memory
- **No Backend Servers**: Direct connection to BitcoinZ network

## 🌐 Network Configuration

Default lightwalletd server: `https://lightd.btcz.rocks:9067`

You can configure custom servers in the app settings.

## 📖 API Reference

### Rust FFI Functions

```rust
// Wallet Management
bitcoinz_init(server_url) -> Result
bitcoinz_create_wallet(seed_phrase) -> WalletInfo
bitcoinz_restore_wallet(seed_phrase, birthday_height) -> WalletInfo

// Balance & Addresses
bitcoinz_get_balance() -> Balance
bitcoinz_get_addresses() -> Addresses
bitcoinz_new_address(address_type) -> Address

// Transactions
bitcoinz_send_transaction(to_address, amount, memo) -> TxResult
bitcoinz_get_transactions() -> TransactionList

// Synchronization
bitcoinz_sync() -> SyncResult
bitcoinz_sync_status() -> SyncStatus

// Message Encryption
bitcoinz_encrypt_message(z_address, message) -> EncryptedData
bitcoinz_decrypt_message(encrypted_data) -> DecryptedMessage

// Cleanup
bitcoinz_free_string(ptr)
bitcoinz_destroy()
```

## 🧪 Testing

```bash
# Run Rust tests
cd rust_core
cargo test

# Run Flutter tests
cd flutter_app
flutter test

# Integration tests
flutter test integration_test/
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/z-bitcoinz/BitcoinZ-Mobile-Wallet/issues)
- **Community**: [BitcoinZ Discord](https://discord.gg/bitcoinz)
- **Website**: [bitcoinz.global](https://bitcoinz.global)

## 🙏 Acknowledgments

- BitcoinZ Community
- BitcoinZ-Light-CLI developers
- Zcash protocol developers
- Flutter and Rust communities