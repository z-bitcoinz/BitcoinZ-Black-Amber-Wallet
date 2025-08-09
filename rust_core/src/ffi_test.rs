use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

// Test function to verify string conversion
#[no_mangle]
pub extern "C" fn test_string_conversion() -> *mut c_char {
    let test_transparent = "t176uDJRs7JakoUVUsAq1DyPRdnof1Qckj6".to_string(); // 35 chars
    let test_shielded = "zs148vpcv4hddj5vyuu5plel9lxmvf5y2sgr88rru4futcqkatreqk0a8v09w5hk7666g2d4eptn82".to_string(); // 78 chars
    
    println!("Rust: Testing string conversion:");
    println!("  t-address: {} (length: {})", test_transparent, test_transparent.len());
    println!("  z-address: {} (length: {})", test_shielded, test_shielded.len());
    
    let json_response = serde_json::json!({
        "transparent": test_transparent,
        "shielded": test_shielded,
        "t_len": test_transparent.len(),
        "z_len": test_shielded.len()
    });
    
    let json_str = json_response.to_string();
    println!("  JSON string: {}", json_str);
    println!("  JSON length: {}", json_str.len());
    
    match CString::new(json_str.clone()) {
        Ok(c_string) => {
            println!("  CString conversion: SUCCESS");
            c_string.into_raw()
        }
        Err(e) => {
            println!("  CString conversion: FAILED - {}", e);
            ptr::null_mut()
        }
    }
}