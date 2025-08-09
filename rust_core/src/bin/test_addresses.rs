use bitcoinz_mobile::mobile_wallet::MobileWallet;

fn main() {
    println!("Testing address generation directly...");
    
    let mut wallet = MobileWallet::new("test".to_string()).unwrap();
    
    match wallet.create_wallet("exotic key total fork concert jacket agree sibling found dust tackle always code genuine sick waste goddess scissors indoor fatigue illegal laundry hip penalty") {
        Ok(wallet_info) => {
            println!("Wallet created successfully!");
            println!("Transparent addresses:");
            for (i, addr) in wallet_info.transparent_addresses.iter().enumerate() {
                println!("  {}: {} (length: {})", i, addr, addr.len());
            }
            println!("Shielded addresses:");
            for (i, addr) in wallet_info.shielded_addresses.iter().enumerate() {
                println!("  {}: {} (length: {})", i, addr, addr.len());
            }
        }
        Err(e) => {
            println!("Error creating wallet: {:?}", e);
        }
    }
}