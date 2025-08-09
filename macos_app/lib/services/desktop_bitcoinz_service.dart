import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';
import '../models/wallet_model.dart';
import '../models/balance_model.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';

class DesktopBitcoinZService {
  static DesktopBitcoinZService? _instance;
  late DynamicLibrary _lib;
  bool _initialized = false;
  final Logger _logger = Logger();

  // Function pointers
  late final Pointer<NativeFunction<Int8 Function(Pointer<Utf8>)>> _init;
  late final Pointer<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>> _createWallet;
  late final Pointer<NativeFunction<Pointer<Utf8> Function()>> _getBalance;
  late final Pointer<NativeFunction<Pointer<Utf8> Function()>> _getTransactions;
  late final Pointer<NativeFunction<Int8 Function()>> _syncWallet;
  late final Pointer<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Double, Pointer<Utf8>)>> _sendTransaction;
  late final Pointer<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>> _generateAddress;
  late final Pointer<NativeFunction<Pointer<Utf8> Function()>> _getAddresses;
  late final Pointer<NativeFunction<Pointer<Utf8> Function()>> _getSyncStatus;
  late final Pointer<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>> _encryptMessage;
  late final Pointer<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>> _decryptMessage;
  
  DesktopBitcoinZService._internal();

  static DesktopBitcoinZService get instance {
    _instance ??= DesktopBitcoinZService._internal();
    return _instance!;
  }

  Future<void> initialize({String? serverUrl}) async {
    if (_initialized) {
      _logger.i('Desktop BitcoinZ service already initialized');
      return;
    }

    try {
      // Load the macOS native library
      if (Platform.isMacOS) {
        // Try to load from the app bundle first
        try {
          _lib = DynamicLibrary.open('libbitcoinz_mobile.dylib');
        } catch (e) {
          // Fallback to relative path
          _lib = DynamicLibrary.open('../rust_core/target/libbitcoinz_mobile_universal.dylib');
        }
      } else {
        throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported for desktop');
      }

      // Bind all functions
      _bindFunctions();

      // Initialize the native wallet
      final serverPtr = (serverUrl ?? AppConstants.defaultLightwalletdServer).toNativeUtf8();
      final initFn = _lib.lookupFunction<Int8 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>('bitcoinz_init');
      final result = initFn(serverPtr);
      
      calloc.free(serverPtr);
      
      if (result != 1) {
        throw Exception('Failed to initialize desktop wallet');
      }

      _initialized = true;
      _logger.i('Desktop BitcoinZ service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Desktop BitcoinZ service: $e');
      rethrow;
    }
  }

  void _bindFunctions() {
    _init = _lib.lookup('bitcoinz_init');
    _createWallet = _lib.lookup('bitcoinz_create_wallet');
    _getBalance = _lib.lookup('bitcoinz_get_balance');
    _getTransactions = _lib.lookup('bitcoinz_get_transactions');
    _syncWallet = _lib.lookup('bitcoinz_sync_wallet');
    _sendTransaction = _lib.lookup('bitcoinz_send_transaction');
    _generateAddress = _lib.lookup('bitcoinz_generate_address');
    _getAddresses = _lib.lookup('bitcoinz_get_addresses');
    _getSyncStatus = _lib.lookup('bitcoinz_get_sync_status');
    _encryptMessage = _lib.lookup('bitcoinz_encrypt_message');
    _decryptMessage = _lib.lookup('bitcoinz_decrypt_message');
  }

  Map<String, dynamic> _parseResponse(Pointer<Utf8> responsePtr) {
    try {
      final responseStr = responsePtr.toDartString();
      calloc.free(responsePtr);
      return jsonDecode(responseStr);
    } catch (e) {
      return {'success': false, 'error': 'Failed to parse response: $e'};
    }
  }

  // Wallet operations
  Future<WalletModel> createWallet(String seedPhrase) async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final seedPtr = seedPhrase.toNativeUtf8();
    final createFn = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('bitcoinz_create_wallet');
    final resultPtr = createFn(seedPtr);
    calloc.free(seedPtr);
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return WalletModel.fromJson(result['data']);
  }

  Future<WalletModel> restoreWallet(String seedPhrase, {int birthdayHeight = 0}) async {
    return createWallet(seedPhrase); // Simplified for now
  }

  Future<BalanceModel> getBalance() async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final balanceFn = _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('bitcoinz_get_balance');
    final resultPtr = balanceFn();
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return BalanceModel.fromJson(result['data']);
  }

  Future<List<TransactionModel>> getTransactions() async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final txFn = _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('bitcoinz_get_transactions');
    final resultPtr = txFn();
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return (result['data'] as List).map((tx) => TransactionModel.fromJson(tx)).toList();
  }

  Future<void> syncWallet() async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final syncFn = _lib.lookupFunction<Int8 Function(), int Function()>('bitcoinz_sync_wallet');
    final result = syncFn();
    
    if (result != 1) {
      throw Exception('Failed to sync wallet');
    }
  }

  Future<Map<String, dynamic>> sendTransaction({
    required String toAddress,
    required double amount,
    String? memo,
  }) async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final addressPtr = toAddress.toNativeUtf8();
    final memoPtr = (memo ?? '').toNativeUtf8();
    
    final sendFn = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>, Double, Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>, double, Pointer<Utf8>)>('bitcoinz_send_transaction');
    
    final resultPtr = sendFn(addressPtr, amount, memoPtr);
    
    calloc.free(addressPtr);
    calloc.free(memoPtr);
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return result['data'];
  }

  Future<String> generateNewAddress(String addressType) async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final typePtr = addressType.toNativeUtf8();
    final genFn = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('bitcoinz_generate_address');
    final resultPtr = genFn(typePtr);
    calloc.free(typePtr);
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return result['data']['address'];
  }

  Future<Map<String, List<String>>> getAddresses() async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final addrFn = _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('bitcoinz_get_addresses');
    final resultPtr = addrFn();
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return Map<String, List<String>>.from(result['data']);
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final statusFn = _lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('bitcoinz_get_sync_status');
    final resultPtr = statusFn();
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return result['data'];
  }

  Future<String> encryptMessage(String zAddress, String message) async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final addressPtr = zAddress.toNativeUtf8();
    final messagePtr = message.toNativeUtf8();
    
    final encFn = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>),
        Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>('bitcoinz_encrypt_message');
    
    final resultPtr = encFn(addressPtr, messagePtr);
    
    calloc.free(addressPtr);
    calloc.free(messagePtr);
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return result['data']['encrypted'];
  }

  Future<String> decryptMessage(String encryptedData) async {
    if (!_initialized) throw Exception('Service not initialized');
    
    final dataPtr = encryptedData.toNativeUtf8();
    final decFn = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<Utf8>), Pointer<Utf8> Function(Pointer<Utf8>)>('bitcoinz_decrypt_message');
    final resultPtr = decFn(dataPtr);
    calloc.free(dataPtr);
    
    final result = _parseResponse(resultPtr);
    if (!result['success']) {
      throw Exception(result['error']);
    }
    
    return result['data']['decrypted'];
  }
}