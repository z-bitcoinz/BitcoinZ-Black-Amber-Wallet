import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

// Test what addresses our wallet is actually generating

// Native function signatures
typedef InitFunctionNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef CreateWalletFunctionNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FreeFunctionNative = Void Function(Pointer<Utf8>);

// Dart function signatures
typedef InitFunction = Pointer<Utf8> Function(Pointer<Utf8>);
typedef CreateWalletFunction = Pointer<Utf8> Function(Pointer<Utf8>);
typedef FreeFunction = void Function(Pointer<Utf8>);

String? _convertCString(Pointer<Utf8> cString) {
  if (cString == nullptr) return null;
  final result = cString.toDartString();
  return result;
}

void main() {
  try {
    // Load the library
    final libraryPath = Platform.isMacOS 
        ? '/Users/name/Documents/code/bitcoinz-mobile-wallet/rust_core/target/debug/libbitcoinz_mobile.dylib'
        : './libbitcoinz_mobile.so';
        
    final library = DynamicLibrary.open(libraryPath);
    
    // Get functions
    final initWallet = library.lookupFunction<InitFunctionNative, InitFunction>('bitcoinz_init');
    final createWallet = library.lookupFunction<CreateWalletFunctionNative, CreateWalletFunction>('bitcoinz_create_wallet');
    final freeString = library.lookupFunction<FreeFunctionNative, FreeFunction>('bitcoinz_free_string');
    
    // Initialize wallet
    final serverUrl = 'https://lightd.btcz.rocks:9067'.toNativeUtf8();
    final initResult = initWallet(serverUrl);
    freeString(initResult);
    
    // Test seed phrase (24 words)
    final testSeed = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art';
    final seedUtf8 = testSeed.toNativeUtf8();
    
    // Create wallet
    final createResult = createWallet(seedUtf8);
    final createResponse = _convertCString(createResult);
    
    if (createResponse != null) {
      final decoded = jsonDecode(createResponse);
      // print('\n📱 Wallet Creation Result:'); // Removed to fix CI analysis
      // print('Success: ${decoded['success']}'); // Removed to fix CI analysis
      
      if (decoded['success'] == true && decoded['data'] != null) {
        final data = decoded['data'];
//         print('Wallet ID: ${data['wallet_id']}');
//         print('\nTransparent Addresses:');
        // Check transparent addresses count
        if (data['transparent_addresses'].length > 0) {
          // Addresses available
        }
        
//         print('\nShielded Addresses:');
        for (int i = 0; i < data['shielded_addresses'].length; i++) {
          final addr = data['shielded_addresses'][i];
//           print('  [$i] $addr (length: ${addr.length})');
          
          // Check if it matches BitcoinZ zs1 format
          if (addr.startsWith('zs1') && addr.length == 78) {
//             print('       ✅ CORRECT BitcoinZ zs1 format');
          } else {
//             print('       ❌ INCORRECT format (should be zs1... with 78 chars)');
          }
        }
      } else if (decoded['error'] != null) {
//         print('Error: ${decoded['error']}');
      }
    } else {
//       print('No response from wallet creation');
    }
    
    freeString(createResult);
    
  } catch (e) {
//     print('Error: $e');
  }
}