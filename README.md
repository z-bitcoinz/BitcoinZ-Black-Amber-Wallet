# BitcoinZ Black Amber - Mobile Wallet

![Version](https://img.shields.io/badge/version-0.8.1-orange.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![BitcoinZ](https://img.shields.io/badge/BitcoinZ-Community%20Edition-gold.svg)

> **After 8 years of dedication to financial freedom, we proudly present the BitcoinZ Mobile Wallet - our gift to the global community!**

A professional, secure, and privacy-focused mobile wallet for BitcoinZ cryptocurrency. Built by the community, for the community, embodying the true spirit of decentralization.

## ✨ What Makes Black Amber Special

**BitcoinZ Black Amber** is not just another wallet - it's your gateway to financial sovereignty and the foundation for tomorrow's privacy revolution. This is more than a wallet; it's a real, working solution that thousands use daily around the world.

### 🎯 **Key Highlights**
- **8 Years in the Making**: Built on years of community dedication and real-world testing
- **True Decentralization**: No backend servers, direct blockchain connection
- **Complete Privacy Control**: Full support for both transparent (t) and shielded (zs) addresses
- **Production Ready**: v0.8.1 - First stable community release
- **Cross-Platform**: Single codebase for all major platforms
- **Professional Grade**: Enterprise-level security with consumer-friendly interface

## 🚀 Core Features

### 💰 **Wallet Operations**
- **Send & Receive**: Seamless transactions with transparent and shielded addresses
- **Balance Management**: Real-time balance updates with confirmation tracking
- **Address Generation**: Create new addresses instantly for enhanced privacy
- **Transaction History**: Complete transaction records with memo support

### 🔒 **Security & Privacy**
- **Biometric Authentication**: Fingerprint and Face ID integration
- **PIN Protection**: Secure 6-digit PIN with auto-lock functionality
- **Encrypted Storage**: All sensitive data encrypted locally on device
- **Secure Messaging**: Private memos with zs-address encryption
- **No Data Collection**: Zero telemetry or tracking

### 👥 **Contact Management**
- **Address Book**: Store and manage your contacts with photos
- **Quick Send**: Send to contacts with a single tap
- **Contact Backup**: Secure backup and restore functionality
- **Validation**: Automatic address validation for safety

### 📊 **Advanced Features**
- **Financial Analytics**: Optional transaction analytics and insights
- **Message Center**: Encrypted memo management system
- **Network Settings**: Connect to custom lightwalletd servers
- **Background Sync**: Keep wallet updated automatically
- **Export Options**: Transaction history export for record keeping

### 🎨 **User Experience**
- **Material 3 Design**: Modern, intuitive interface
- **Dark/Light Themes**: Adaptive interface for any environment
- **Multi-language Ready**: Internationalization support
- **Accessibility**: Full accessibility compliance
- **Responsive Design**: Optimized for phones, tablets, and desktop

## 🏗️ Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 BitcoinZ Black Amber v0.8.1                │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐   │
│  │   Flutter UI    │ │  State Mgmt     │ │   Services   │   │
│  │  (Material 3)   │ │  (Provider)     │ │  (Native)    │   │
│  └─────────────────┘ └─────────────────┘ └──────────────┘   │
└─────────────────────┬───────────────────────────────────────┘
                      │ Flutter Rust Bridge (FFI)
┌─────────────────────┴───────────────────────────────────────┐
│                  Rust Core Library                         │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────────┐   │
│  │ Wallet Engine   │ │  Cryptography   │ │   Network    │   │
│  │   (Native)      │ │  (zk-SNARKs)    │ │  (Direct)    │   │
│  └─────────────────┘ └─────────────────┘ └──────────────┘   │
└─────────────────────┬───────────────────────────────────────┘
                      │ Direct Protocol Connection
              ┌───────┴────────┐
              │ BitcoinZ Network │
              │  (lightwalletd)  │
              └──────────────────┘
```

### **Why This Architecture Matters**
- **Native Performance**: Rust core for cryptographic operations ensures maximum security and speed
- **Cross-Platform**: Single Flutter codebase deploys to all major platforms
- **Direct Connection**: No intermediary servers - your wallet connects directly to BitcoinZ network
- **Memory Safe**: Rust prevents common security vulnerabilities
- **Future Proof**: Architecture supports advanced features and protocol upgrades

## 📱 Platform Support

| Platform | Status | Install Method |
|----------|---------|----------------|
| **Android** | ✅ Production | APK / Google Play Store |
| **iOS** | ✅ Production | TestFlight / App Store |
| **macOS** | ✅ Production | DMG / Mac App Store |
| **Windows** | ✅ Production | MSI Installer |
| **Linux** | ✅ Production | AppImage / Snap |

## 🛠️ Quick Start

### For Users

1. **Download** the latest release for your platform
2. **Install** using your platform's standard method
3. **Launch** and choose "Create New Wallet" or "Restore Wallet"
4. **Secure** with PIN and biometric authentication
5. **Start** sending and receiving BitcoinZ!

### For Developers

```bash
# Clone repository
git clone https://github.com/z-bitcoinz/BitcoinZ-black-amber.git
cd BitcoinZ-black-amber

# Setup environment
./scripts/setup_environment.sh

# Build for your platform
cd flutter_app
flutter run -d [device]
```

## 🔧 Configuration

### **Default Settings**
- **Server**: `https://lightd.btcz.rocks:9067`
- **Confirmations**: 1 for transparent, 2 for shielded
- **Auto-lock**: 5 minutes of inactivity
- **Sync**: Automatic background synchronization

### **Customization**
All settings can be customized through the app's Settings screen:
- Custom lightwalletd servers
- Security preferences
- Display options
- Notification settings

## 🔒 Security Features

### **On-Device Security**
- All private keys stored locally using platform secure storage
- Biometric authentication (Face ID, Touch ID, Fingerprint)
- Automatic wallet locking after inactivity
- PIN protection with failed attempt lockout

### **Network Security**  
- Direct TLS connection to BitcoinZ network
- No data transmitted to third-party servers
- Full node verification of transactions
- zk-SNARK privacy proofs for shielded transactions

### **Code Security**
- Memory-safe Rust core prevents buffer overflows
- Flutter secure coding practices
- No sensitive data in application logs
- Proper cleanup of cryptographic material

## 📊 What's New in v0.8.1

### **🎉 First Production Release**
After 8 years of community development, we're proud to present the first stable release of BitcoinZ Black Amber.

### **✨ Major Features**
- Complete wallet functionality with both transparent and shielded addresses
- Professional Material 3 interface design
- Comprehensive contact management with photo support
- Encrypted messaging system with memo support
- Financial analytics and transaction insights
- Multi-platform support (Android, iOS, macOS, Windows, Linux)

### **🔧 Technical Improvements**
- Native Rust core for maximum performance and security
- Flutter Rust Bridge for seamless cross-platform operation
- Direct lightwalletd protocol implementation
- Optimized sync and balance calculation algorithms
- Background processing and notification system

### **🎨 User Experience**
- Intuitive onboarding flow
- Context-aware help system
- Accessibility improvements
- Responsive design for all screen sizes
- Dark/light theme support

## 🌐 Community

### **BitcoinZ Values**
- **Decentralization**: No central authority, community-driven development
- **Privacy**: Your financial data belongs to you alone
- **Security**: Military-grade cryptography protects your assets
- **Accessibility**: Financial freedom for everyone, everywhere
- **Transparency**: Open source, auditable code

### **Get Involved**
- **Community**: [BitcoinZ Discord](https://discord.gg/bitcoinz)
- **Website**: [bitcoinz.global](https://bitcoinz.global)
- **GitHub**: [BitcoinZ Organization](https://github.com/z-bitcoinz)
- **Social**: Follow us on Twitter [@BitcoinZTeam](https://twitter.com/BitcoinZTeam)

## 📞 Support

### **Getting Help**
- **Issues**: [GitHub Issues](https://github.com/z-bitcoinz/BitcoinZ-black-amber/issues)
- **Documentation**: [User Guide](docs/USER_GUIDE.md)
- **Community Support**: [BitcoinZ Discord #wallet-support](https://discord.gg/bitcoinz)
- **FAQ**: [Frequently Asked Questions](docs/FAQ.md)

### **Reporting Bugs**
1. Check existing [GitHub Issues](https://github.com/z-bitcoinz/BitcoinZ-black-amber/issues)
2. Create a new issue with detailed reproduction steps
3. Include your platform, version, and relevant logs
4. Tag with appropriate labels (bug, enhancement, etc.)

## 🎯 Roadmap

### **Immediate (v0.8.x)**
- [ ] Hardware wallet integration (Ledger, Trezor)
- [ ] Advanced transaction scheduling
- [ ] Multi-language localization
- [ ] Enhanced notification system

### **Short Term (v0.9.x)**
- [ ] DeFi integration features
- [ ] Advanced privacy tools
- [ ] Cross-chain compatibility
- [ ] Enhanced analytics dashboard

### **Long Term (v1.0+)**
- [ ] Desktop trading interface
- [ ] Lightning Network integration
- [ ] Advanced scripting support
- [ ] Enterprise features

## 📄 License

BitcoinZ Black Amber is released under the **MIT License**. See [LICENSE](LICENSE) for details.

This means you can:
- ✅ Use commercially
- ✅ Modify and distribute
- ✅ Use privately
- ✅ Include in proprietary software

## 🙏 Acknowledgments

### **BitcoinZ Community**
Special thanks to the incredible BitcoinZ community whose 8 years of dedication made this wallet possible.

### **Core Contributors**
- BitcoinZ Core Development Team
- Community Beta Testers
- Security Audit Contributors
- Translation Teams

### **Technology Stack**
- **Flutter Team**: For the amazing cross-platform framework
- **Rust Community**: For memory-safe systems programming
- **Zcash Protocol**: For privacy-preserving cryptocurrency technology
- **BitcoinZ Network**: For the decentralized infrastructure

---

## 🚀 Ready to Experience True Financial Freedom?

Download BitcoinZ Black Amber v0.8.1 today and join thousands of users worldwide who have chosen financial sovereignty.

**BitcoinZ: Your Keys, Your Coins, Your Freedom.**

*First release. Unlimited potential. The best is yet to come!*

---

<div align="center">

### [Download Latest Release](https://github.com/z-bitcoinz/BitcoinZ-black-amber/releases/latest) | [User Guide](docs/USER_GUIDE.md) | [Community](https://discord.gg/bitcoinz)

[![GitHub stars](https://img.shields.io/github/stars/z-bitcoinz/BitcoinZ-black-amber.svg?style=social&label=Star)](https://github.com/z-bitcoinz/BitcoinZ-black-amber/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/z-bitcoinz/BitcoinZ-black-amber.svg?style=social&label=Fork)](https://github.com/z-bitcoinz/BitcoinZ-black-amber/network/members)

</div>