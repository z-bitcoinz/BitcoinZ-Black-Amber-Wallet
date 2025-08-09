// FFI Bridge utilities and helper functions
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

/// Convert a Rust String to a C-compatible string pointer
/// The caller is responsible for freeing this memory using bitcoinz_free_string
pub fn rust_string_to_c(s: String) -> *mut c_char {
    match CString::new(s) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => {
            // If the string contains null bytes, return a null pointer
            log::error!("Failed to convert Rust string to C string: contains null bytes");
            ptr::null_mut()
        }
    }
}

/// Convert a C string pointer to a Rust String
/// Returns None if the pointer is null or invalid UTF-8
pub unsafe fn c_string_to_rust(c_str: *const c_char) -> Option<String> {
    if c_str.is_null() {
        return None;
    }
    
    match CStr::from_ptr(c_str).to_str() {
        Ok(str_slice) => Some(str_slice.to_string()),
        Err(e) => {
            log::error!("Failed to convert C string to Rust string: {}", e);
            None
        }
    }
}

/// Validate that a C string pointer is not null and convert to Rust String
pub unsafe fn validate_and_convert_c_string(c_str: *const c_char, param_name: &str) -> Result<String, String> {
    if c_str.is_null() {
        return Err(format!("{} cannot be null", param_name));
    }
    
    match CStr::from_ptr(c_str).to_str() {
        Ok(str_slice) => Ok(str_slice.to_string()),
        Err(_) => Err(format!("{} contains invalid UTF-8", param_name)),
    }
}

/// Create a standardized JSON error response
pub fn create_error_json(error_message: &str) -> String {
    serde_json::json!({
        "success": false,
        "error": error_message,
        "timestamp": chrono::Utc::now().timestamp()
    }).to_string()
}

/// Create a standardized JSON success response
pub fn create_success_json(data: serde_json::Value) -> String {
    serde_json::json!({
        "success": true,
        "data": data,
        "timestamp": chrono::Utc::now().timestamp()
    }).to_string()
}

/// Macro to handle common FFI error patterns
#[macro_export]
macro_rules! ffi_try {
    ($expr:expr) => {
        match $expr {
            Ok(val) => val,
            Err(e) => {
                let error_response = crate::ffi_bridge::create_error_json(&e.to_string());
                return crate::ffi_bridge::rust_string_to_c(error_response);
            }
        }
    };
}

/// Macro to safely convert C string parameters
#[macro_export]
macro_rules! c_str_param {
    ($ptr:expr, $name:expr) => {
        unsafe {
            match crate::ffi_bridge::validate_and_convert_c_string($ptr, $name) {
                Ok(s) => s,
                Err(e) => {
                    let error_response = crate::ffi_bridge::create_error_json(&e);
                    return crate::ffi_bridge::rust_string_to_c(error_response);
                }
            }
        }
    };
}

/// Test functions for FFI bridge
#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_rust_to_c_string_conversion() {
        let rust_string = "Hello, World!".to_string();
        let c_ptr = rust_string_to_c(rust_string.clone());
        
        assert!(!c_ptr.is_null());
        
        unsafe {
            let converted_back = c_string_to_rust(c_ptr).unwrap();
            assert_eq!(converted_back, rust_string);
            
            // Free the allocated memory
            let _ = CString::from_raw(c_ptr);
        }
    }

    #[test]
    fn test_null_c_string_handling() {
        unsafe {
            let result = c_string_to_rust(ptr::null());
            assert!(result.is_none());
        }
    }

    #[test]
    fn test_error_json_creation() {
        let error_msg = "Test error message";
        let json = create_error_json(error_msg);
        
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed["success"], false);
        assert_eq!(parsed["error"], error_msg);
        assert!(parsed["timestamp"].is_number());
    }

    #[test]
    fn test_success_json_creation() {
        let data = serde_json::json!({"test": "value"});
        let json = create_success_json(data.clone());
        
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed["success"], true);
        assert_eq!(parsed["data"], data);
        assert!(parsed["timestamp"].is_number());
    }
}