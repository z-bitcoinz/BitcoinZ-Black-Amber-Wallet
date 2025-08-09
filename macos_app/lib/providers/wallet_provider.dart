import 'package:flutter/foundation.dart';
import '../models/wallet_model.dart';
import '../models/balance_model.dart';
import '../models/transaction_model.dart';
import '../services/desktop_bitcoinz_service.dart';

class WalletProvider with ChangeNotifier {
  WalletModel? _wallet;
  BalanceModel _balance = BalanceModel.empty();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  Map<String, List<String>> _addresses = {'transparent': [], 'shielded': []};

  // Getters
  WalletModel? get wallet => _wallet;
  BalanceModel get balance => _balance;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  Map<String, List<String>> get addresses => _addresses;
  bool get hasWallet => _wallet != null;

  // Desktop-specific getters
  bool get isWalletInitialized => hasWallet;
  int get totalAddresses => _addresses['transparent']!.length + _addresses['shielded']!.length;

  /// Initialize or restore wallet
  Future<void> createWallet(String seedPhrase) async {
    _setLoading(true);
    _clearError();

    try {
      final walletInfo = await DesktopBitcoinZService.instance.createWallet(seedPhrase);
      _wallet = walletInfo;
      await _refreshWalletData();
      notifyListeners();
    } catch (e) {
      _setError('Failed to create wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Restore wallet from seed phrase
  Future<void> restoreWallet(String seedPhrase, {int birthdayHeight = 0}) async {
    _setLoading(true);
    _clearError();

    try {
      final walletInfo = await DesktopBitcoinZService.instance.restoreWallet(
        seedPhrase,
        birthdayHeight: birthdayHeight,
      );
      _wallet = walletInfo;
      await _refreshWalletData();
      notifyListeners();
    } catch (e) {
      _setError('Failed to restore wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh all wallet data
  Future<void> refreshWallet() async {
    if (!hasWallet) return;
    
    _setLoading(true);
    _clearError();

    try {
      await _refreshWalletData();
    } catch (e) {
      _setError('Failed to refresh wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sync wallet with blockchain
  Future<void> syncWallet() async {
    if (!hasWallet) return;

    _setSyncing(true);
    _clearError();

    try {
      await DesktopBitcoinZService.instance.syncWallet();
      await _refreshWalletData();
    } catch (e) {
      _setError('Failed to sync wallet: $e');
    } finally {
      _setSyncing(false);
    }
  }

  /// Send transaction
  Future<String?> sendTransaction({
    required String toAddress,
    required double amount,
    String? memo,
  }) async {
    if (!hasWallet) {
      _setError('No wallet available');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await DesktopBitcoinZService.instance.sendTransaction(
        toAddress: toAddress,
        amount: amount,
        memo: memo,
      );
      
      // Refresh wallet data after sending
      await _refreshWalletData();
      
      return result['txid'];
    } catch (e) {
      _setError('Failed to send transaction: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate new address
  Future<String?> generateNewAddress(String addressType) async {
    if (!hasWallet) {
      _setError('No wallet available');
      return null;
    }

    try {
      final address = await DesktopBitcoinZService.instance.generateNewAddress(addressType);
      await _loadAddresses(); // Refresh addresses
      return address;
    } catch (e) {
      _setError('Failed to generate new address: $e');
      return null;
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>?> getSyncStatus() async {
    if (!hasWallet) return null;

    try {
      return await DesktopBitcoinZService.instance.getSyncStatus();
    } catch (e) {
      _setError('Failed to get sync status: $e');
      return null;
    }
  }

  /// Encrypt message for z-address
  Future<String?> encryptMessage(String zAddress, String message) async {
    if (!hasWallet) {
      _setError('No wallet available');
      return null;
    }

    try {
      return await DesktopBitcoinZService.instance.encryptMessage(zAddress, message);
    } catch (e) {
      _setError('Failed to encrypt message: $e');
      return null;
    }
  }

  /// Decrypt message
  Future<String?> decryptMessage(String encryptedData) async {
    if (!hasWallet) {
      _setError('No wallet available');
      return null;
    }

    try {
      return await DesktopBitcoinZService.instance.decryptMessage(encryptedData);
    } catch (e) {
      _setError('Failed to decrypt message: $e');
      return null;
    }
  }

  /// Private helper methods
  Future<void> _refreshWalletData() async {
    await Future.wait([
      _loadBalance(),
      _loadTransactions(),
      _loadAddresses(),
    ]);
    notifyListeners();
  }

  Future<void> _loadBalance() async {
    try {
      _balance = await DesktopBitcoinZService.instance.getBalance();
    } catch (e) {
      // Don't set error here, let it be handled by parent method
      rethrow;
    }
  }

  Future<void> _loadTransactions() async {
    try {
      _transactions = await DesktopBitcoinZService.instance.getTransactions();
      // Sort by timestamp, newest first
      _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadAddresses() async {
    try {
      _addresses = await DesktopBitcoinZService.instance.getAddresses();
    } catch (e) {
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all wallet data (for logout)
  void clearWallet() {
    _wallet = null;
    _balance = BalanceModel.empty();
    _transactions = [];
    _addresses = {'transparent': [], 'shielded': []};
    _clearError();
    notifyListeners();
  }

  /// Get recent transactions (last 10)
  List<TransactionModel> get recentTransactions {
    return _transactions.take(10).toList();
  }

  /// Get transactions by type
  List<TransactionModel> getTransactionsByType(String type) {
    return _transactions.where((tx) => tx.type == type).toList();
  }

  /// Check if address belongs to this wallet
  bool isMyAddress(String address) {
    return _addresses['transparent']!.contains(address) ||
           _addresses['shielded']!.contains(address);
  }
}