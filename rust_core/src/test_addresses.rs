use crate::mobile_wallet::MobileWallet;

impl MobileWallet {
    // Make private methods public for testing
    pub fn generate_transparent_address_test(&self, index: u32) -> crate::error_handling::WalletResult<String> {
        self.generate_transparent_address(index)
    }
    
    pub fn generate_shielded_address_test(&self, index: u32) -> crate::error_handling::WalletResult<String> {
        self.generate_shielded_address(index)
    }
}

#[test]
fn test_address_generation() {
    let mut wallet = MobileWallet::new("test".to_string()).unwrap();
    
    // Set a test seed phrase  
    wallet.seed_phrase = Some("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art".to_string());
    wallet.is_initialized = true;
    
    // Test transparent address generation
    let t_addr = wallet.generate_transparent_address(0).unwrap();
    println!("Generated transparent address: {} (length: {})", t_addr, t_addr.len());
    assert!(t_addr.starts_with("t1"));
    assert_eq!(t_addr.len(), 35);
    
    // Test shielded address generation  
    let z_addr = wallet.generate_shielded_address(0).unwrap();
    println!("Generated shielded address: {} (length: {})", z_addr, z_addr.len());
    assert!(z_addr.starts_with("zs1"));
    assert_eq!(z_addr.len(), 78);
}