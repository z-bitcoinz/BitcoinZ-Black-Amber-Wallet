use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use crate::{bitcoinz_create_wallet, bitcoinz_restore_wallet};

// Test function that calls the exact same FFI functions Flutter is using
#[no_mangle]
pub extern "C" fn debug_ffi_wallet_creation() -> *mut c_char {
    println!("🔍 FFI Debug: Starting wallet creation test...");
    
    // Test with a deterministic 24-word seed phrase to check address generation consistency  
    let test_seed = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art";
    println!("🔍 FFI Debug: Using seed phrase: {}", test_seed);
    
    let seed_cstring = CString::new(test_seed).unwrap();
    let seed_ptr = seed_cstring.as_ptr();
    
    println!("🔍 FFI Debug: Calling bitcoinz_create_wallet via FFI...");
    
    // Call the exact same function that Flutter calls
    let result_ptr = unsafe { bitcoinz_create_wallet(seed_ptr) };
    
    if result_ptr.is_null() {
        println!("❌ FFI Debug: Got null pointer from bitcoinz_create_wallet");
        return std::ptr::null_mut();
    }
    
    // Get the result string
    let result_str = unsafe { CStr::from_ptr(result_ptr).to_str().unwrap() };
    println!("🔍 FFI Debug: Raw FFI response: {}", result_str);
    
    // Parse and analyze the response
    match serde_json::from_str::<serde_json::Value>(result_str) {
        Ok(json) => {
            println!("🔍 FFI Debug: Parsed JSON successfully");
            
            if let Some(data) = json.get("data") {
                if let Some(transparent_addrs) = data.get("transparent_addresses") {
                    if let Some(addrs_array) = transparent_addrs.as_array() {
                        println!("🔍 FFI Debug: Transparent addresses from FFI:");
                        for (i, addr) in addrs_array.iter().enumerate() {
                            if let Some(addr_str) = addr.as_str() {
                                println!("  [{}]: \"{}\" ({} chars)", i, addr_str, addr_str.len());
                            }
                        }
                    }
                }
                
                if let Some(shielded_addrs) = data.get("shielded_addresses") {
                    if let Some(addrs_array) = shielded_addrs.as_array() {
                        println!("🔍 FFI Debug: Shielded addresses from FFI:");
                        for (i, addr) in addrs_array.iter().enumerate() {
                            if let Some(addr_str) = addr.as_str() {
                                println!("  [{}]: \"{}\" ({} chars)", i, addr_str, addr_str.len());
                            }
                        }
                    }
                }
            }
        }
        Err(e) => {
            println!("❌ FFI Debug: Failed to parse JSON: {}", e);
        }
    }
    
    // Return the original result
    result_ptr
}