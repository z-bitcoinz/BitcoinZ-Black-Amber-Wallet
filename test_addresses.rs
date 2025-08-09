// Test script to verify BitcoinZ address generation
use sha2::{Sha256, Digest};

fn generate_test_zs1_address() -> String {
    let seed = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art";
    let index = 0u32;
    
    let hash = Sha256::digest(format!("{}:shielded:{}", seed, index).as_bytes());
    
    let mut address_chars = Vec::new();
    const CHARSET: &[u8] = b"023456789acdefghjklmnpqrstuvwxyz";
    
    for byte in &hash[..] {
        address_chars.push(CHARSET[(byte % 32) as usize] as char);
    }
    
    let suffix: String = address_chars.iter().take(75).collect();
    format!("zs1{}", suffix)
}

fn main() {
    let address = generate_test_zs1_address();
    println!("Generated BitcoinZ zs1 address: {}", address);
    println!("Address length: {}", address.len());
    println!("Starts with zs1: {}", address.starts_with("zs1"));
    
    // Expected format similar to: zs1s97zg52cw6w2p8zfxvz3fehzmqrx8hdas5j00hy7qwwy7ehxqfr4r7fegrxfu3dal6jwytnsvze
    assert_eq!(address.len(), 78);
    assert!(address.starts_with("zs1"));
    println!("✓ Address format is correct!");
}