use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;
use serde_json;

pub mod mobile_wallet;
pub mod ffi_bridge; 
pub mod error_handling;
pub mod lightwalletd_client;
pub mod ffi_test;
pub mod ffi_debug;

#[cfg(test)]
mod test_addresses;

pub use mobile_wallet::MobileWallet;
pub use error_handling::{WalletError, WalletResult};

// Global wallet instance
static mut WALLET_INSTANCE: Option<MobileWallet> = None;

// Utility function to convert C string to Rust string
unsafe fn c_str_to_string(c_str: *const c_char) -> Result<String, WalletError> {
    if c_str.is_null() {
        return Err(WalletError::InvalidInput("Null pointer provided".to_string()));
    }
    
    CStr::from_ptr(c_str)
        .to_str()
        .map(|s| s.to_string())
        .map_err(|e| WalletError::InvalidInput(format!("Invalid UTF-8: {}", e)))
}

// Utility function to convert Rust string to C string
fn string_to_c_str(s: String) -> *mut c_char {
    log::info!("🔥 Converting Rust string to C string: length={} chars", s.len());
    if s.len() > 500 {
        log::info!("🔥 String preview: {}...[truncated]", &s[0..500]);
    } else {
        log::info!("🔥 Full string: {}", s);
    }
    
    match CString::new(s.clone()) {
        Ok(c_string) => {
            let ptr = c_string.into_raw();
            log::info!("✅ Successfully converted to C string");
            ptr
        }
        Err(e) => {
            log::error!("❌ Failed to convert to C string: {} (string length: {})", e, s.len());
            ptr::null_mut()
        }
    }
}

// Utility function to create error response
fn create_error_response(error: &str) -> *mut c_char {
    let response = serde_json::json!({
        "success": false,
        "error": error
    });
    string_to_c_str(response.to_string())
}

// Utility function to create success response
fn create_success_response(data: serde_json::Value) -> *mut c_char {
    let response = serde_json::json!({
        "success": true,
        "data": data
    });
    string_to_c_str(response.to_string())
}

/// Initialize the mobile wallet with optional configuration
#[no_mangle]
pub extern "C" fn bitcoinz_init(server_url: *const c_char) -> *mut c_char {
    unsafe {
        let server = if server_url.is_null() {
            "https://lightd.btcz.rocks:9067".to_string()
        } else {
            match c_str_to_string(server_url) {
                Ok(s) => s,
                Err(e) => return create_error_response(&e.to_string()),
            }
        };

        match MobileWallet::new(server) {
            Ok(wallet) => {
                WALLET_INSTANCE = Some(wallet);
                create_success_response(serde_json::json!({
                    "message": "Wallet initialized successfully"
                }))
            }
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Create a new wallet with seed phrase
#[no_mangle]
pub extern "C" fn bitcoinz_create_wallet(seed_phrase: *const c_char) -> *mut c_char {
    unsafe {
        log::info!("🎆 Creating new wallet - clearing any existing wallet state");
        
        // Clear existing wallet instance to ensure fresh creation
        WALLET_INSTANCE = None;
        
        // Initialize fresh wallet instance
        match MobileWallet::new("https://lightd.btcz.rocks:9067".to_string()) {
            Ok(fresh_wallet) => {
                WALLET_INSTANCE = Some(fresh_wallet);
                log::info!("✨ Fresh wallet instance created");
            }
            Err(e) => {
                log::error!("❌ Failed to create fresh wallet instance: {}", e);
                return create_error_response(&format!("Failed to initialize wallet: {}", e));
            }
        }
        
        let wallet = match WALLET_INSTANCE.as_mut() {
            Some(w) => w,
            None => return create_error_response("Failed to create wallet instance"),
        };

        let seed = match c_str_to_string(seed_phrase) {
            Ok(s) => s,
            Err(e) => return create_error_response(&e.to_string()),
        };

        match wallet.create_wallet(&seed) {
            Ok(wallet_info) => {
                let response_json = serde_json::json!({
                    "wallet_id": wallet_info.wallet_id,
                    "transparent_addresses": wallet_info.transparent_addresses,
                    "shielded_addresses": wallet_info.shielded_addresses
                });
                
                create_success_response(response_json)
            },
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Restore wallet from seed phrase with optional birthday height
#[no_mangle] 
pub extern "C" fn bitcoinz_restore_wallet(
    seed_phrase: *const c_char,
    birthday_height: u32
) -> *mut c_char {
    unsafe {
        log::info!("🔄 Restoring wallet - clearing any existing wallet state");
        
        // Clear existing wallet instance to ensure fresh restoration
        WALLET_INSTANCE = None;
        
        // Initialize fresh wallet instance
        match MobileWallet::new("https://lightd.btcz.rocks:9067".to_string()) {
            Ok(fresh_wallet) => {
                WALLET_INSTANCE = Some(fresh_wallet);
                log::info!("✨ Fresh wallet instance created for restoration");
            }
            Err(e) => {
                log::error!("❌ Failed to create fresh wallet instance: {}", e);
                return create_error_response(&format!("Failed to initialize wallet: {}", e));
            }
        }
        
        let wallet = match WALLET_INSTANCE.as_mut() {
            Some(w) => w,
            None => return create_error_response("Failed to create wallet instance"),
        };

        let seed = match c_str_to_string(seed_phrase) {
            Ok(s) => s,
            Err(e) => return create_error_response(&e.to_string()),
        };

        match wallet.restore_wallet(&seed, birthday_height) {
            Ok(wallet_info) => {
                // Debug logging for address lengths
                log::info!("🔄 Rust wallet restored successfully!");
                log::info!("  wallet_id: {}", wallet_info.wallet_id);
                log::info!("  birthday_height: {}", birthday_height);
                log::info!("  transparent_addresses: {} addresses", wallet_info.transparent_addresses.len());
                for (i, addr) in wallet_info.transparent_addresses.iter().enumerate() {
                    log::info!("    {}: {} (length: {})", i, addr, addr.len());
                }
                log::info!("  shielded_addresses: {} addresses", wallet_info.shielded_addresses.len());
                for (i, addr) in wallet_info.shielded_addresses.iter().enumerate() {
                    log::info!("    {}: {} (length: {})", i, addr, addr.len());
                }
                
                let response_json = serde_json::json!({
                    "wallet_id": wallet_info.wallet_id,
                    "birthday_height": birthday_height,
                    "transparent_addresses": wallet_info.transparent_addresses,
                    "shielded_addresses": wallet_info.shielded_addresses
                });
                
                let response_str = response_json.to_string();
                log::info!("📤 FFI Response JSON length: {} chars", response_str.len());
                log::info!("📤 FFI Response full JSON:");
                log::info!("{}", response_str);
                
                create_success_response(response_json)
            },
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Get wallet balance (transparent + shielded)
#[no_mangle]
pub extern "C" fn bitcoinz_get_balance() -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_mut() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        match wallet.get_balance() {
            Ok(balance) => create_success_response(serde_json::json!({
                "transparent": balance.transparent,
                "shielded": balance.shielded,
                "total": balance.total,
                "unconfirmed": balance.unconfirmed
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Get all wallet addresses
#[no_mangle]
pub extern "C" fn bitcoinz_get_addresses() -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_ref() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        match wallet.get_addresses() {
            Ok(addresses) => create_success_response(serde_json::json!({
                "transparent": addresses.transparent,
                "shielded": addresses.shielded
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Generate new address (transparent or shielded)
#[no_mangle]
pub extern "C" fn bitcoinz_new_address(address_type: *const c_char) -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_mut() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        let addr_type = match c_str_to_string(address_type) {
            Ok(s) => s,
            Err(e) => return create_error_response(&e.to_string()),
        };

        match wallet.generate_new_address(&addr_type) {
            Ok(address) => create_success_response(serde_json::json!({
                "address": address,
                "type": addr_type
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Sync wallet with blockchain
#[no_mangle]
pub extern "C" fn bitcoinz_sync() -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_mut() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        match wallet.sync() {
            Ok(sync_result) => create_success_response(serde_json::json!({
                "synced_blocks": sync_result.blocks_synced,
                "current_height": sync_result.current_height,
                "total_height": sync_result.total_height
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Get sync status
#[no_mangle]
pub extern "C" fn bitcoinz_sync_status() -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_ref() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        match wallet.get_sync_status() {
            Ok(status) => create_success_response(serde_json::json!({
                "is_syncing": status.is_syncing,
                "current_block": status.current_block,
                "total_blocks": status.total_blocks,
                "progress": status.progress
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Send transaction
#[no_mangle]
pub extern "C" fn bitcoinz_send_transaction(
    to_address: *const c_char,
    amount_zatoshis: u64,
    memo: *const c_char
) -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_mut() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        let to_addr = match c_str_to_string(to_address) {
            Ok(s) => s,
            Err(e) => return create_error_response(&e.to_string()),
        };

        let memo_str = if memo.is_null() {
            None
        } else {
            match c_str_to_string(memo) {
                Ok(s) => Some(s),
                Err(e) => return create_error_response(&e.to_string()),
            }
        };

        match wallet.send_transaction(&to_addr, amount_zatoshis, memo_str.as_deref()) {
            Ok(tx_result) => create_success_response(serde_json::json!({
                "txid": tx_result.txid,
                "amount": amount_zatoshis,
                "fee": tx_result.fee
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Get transaction history  
#[no_mangle]
pub extern "C" fn bitcoinz_get_transactions() -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_ref() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        match wallet.get_transactions() {
            Ok(transactions) => {
                let tx_json: Vec<serde_json::Value> = transactions.iter().map(|tx| {
                    serde_json::json!({
                        "txid": tx.txid,
                        "amount": tx.amount,
                        "block_height": tx.block_height,
                        "timestamp": tx.timestamp,
                        "memo": tx.memo,
                        "type": tx.tx_type
                    })
                }).collect();
                
                create_success_response(serde_json::json!({
                    "transactions": tx_json
                }))
            }
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Encrypt message for z-address
#[no_mangle]
pub extern "C" fn bitcoinz_encrypt_message(
    z_address: *const c_char,
    message: *const c_char
) -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_ref() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        let address = match c_str_to_string(z_address) {
            Ok(s) => s,
            Err(e) => return create_error_response(&e.to_string()),
        };

        let msg = match c_str_to_string(message) {
            Ok(s) => s,
            Err(e) => return create_error_response(&e.to_string()),
        };

        match wallet.encrypt_message(&address, &msg) {
            Ok(encrypted) => create_success_response(serde_json::json!({
                "encrypted": encrypted
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Decrypt message
#[no_mangle]
pub extern "C" fn bitcoinz_decrypt_message(encrypted_data: *const c_char) -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_ref() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        let encrypted = match c_str_to_string(encrypted_data) {
            Ok(s) => s,
            Err(e) => return create_error_response(&e.to_string()),
        };

        match wallet.decrypt_message(&encrypted) {
            Ok(decrypted) => create_success_response(serde_json::json!({
                "decrypted": decrypted
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Get private key for a transparent address by index
#[no_mangle]
pub extern "C" fn bitcoinz_get_private_key(address_index: u32) -> *mut c_char {
    unsafe {
        let wallet = match WALLET_INSTANCE.as_ref() {
            Some(w) => w,
            None => return create_error_response("Wallet not initialized"),
        };

        match wallet.get_private_key(address_index) {
            Ok(private_key) => create_success_response(serde_json::json!({
                "private_key": private_key,
                "address_index": address_index
            })),
            Err(e) => create_error_response(&e.to_string()),
        }
    }
}

/// Free memory allocated by the library
#[no_mangle]
pub extern "C" fn bitcoinz_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

/// Cleanup and destroy wallet instance
#[no_mangle]
pub extern "C" fn bitcoinz_destroy() -> *mut c_char {
    unsafe {
        WALLET_INSTANCE = None;
        create_success_response(serde_json::json!({
            "message": "Wallet destroyed successfully"
        }))
    }
}