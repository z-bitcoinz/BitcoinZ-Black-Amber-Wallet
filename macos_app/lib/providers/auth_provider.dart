import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const String _hasWalletKey = 'has_wallet';
  static const String _walletIdKey = 'wallet_id';
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  bool _isAuthenticated = false;
  bool _hasWallet = false;
  String? _walletId;
  bool _biometricsEnabled = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get hasWallet => _hasWallet;
  String? get walletId => _walletId;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize auth provider
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      await _loadStoredData();
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Register new wallet
  Future<bool> registerWallet(String walletId) async {
    _setLoading(true);
    _clearError();

    try {
      await _storage.write(key: _hasWalletKey, value: 'true');
      await _storage.write(key: _walletIdKey, value: walletId);
      
      _hasWallet = true;
      _walletId = walletId;
      _isAuthenticated = false; // Still need to authenticate
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to register wallet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Authenticate user (simplified for desktop)
  Future<bool> authenticate() async {
    if (!_hasWallet) {
      _setError('No wallet found');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // For desktop, we'll implement a simpler authentication
      // In a real implementation, you might use system keychain or similar
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Authentication failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isAuthenticated = false;
    _clearError();
    notifyListeners();
  }

  /// Reset wallet (clear all stored data)
  Future<void> resetWallet() async {
    _setLoading(true);
    
    try {
      await _storage.deleteAll();
      
      _hasWallet = false;
      _walletId = null;
      _isAuthenticated = false;
      _biometricsEnabled = false;
      _clearError();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Enable/disable biometrics
  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      await _storage.write(key: _biometricsEnabledKey, value: enabled.toString());
      _biometricsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update biometrics setting: $e');
    }
  }

  /// Check if biometrics are available
  Future<bool> isBiometricsAvailable() async {
    // For desktop, biometrics might not be available
    // This would need to be implemented based on platform capabilities
    return false;
  }

  /// Load stored authentication data
  Future<void> _loadStoredData() async {
    final hasWalletStr = await _storage.read(key: _hasWalletKey);
    final walletId = await _storage.read(key: _walletIdKey);
    final biometricsStr = await _storage.read(key: _biometricsEnabledKey);

    _hasWallet = hasWalletStr == 'true';
    _walletId = walletId;
    _biometricsEnabled = biometricsStr == 'true';
    
    // Don't auto-authenticate on desktop for security
    _isAuthenticated = false;
    
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if app needs initial setup
  bool get needsSetup => !_hasWallet;

  /// Check if user needs to authenticate
  bool get needsAuthentication => _hasWallet && !_isAuthenticated;
}