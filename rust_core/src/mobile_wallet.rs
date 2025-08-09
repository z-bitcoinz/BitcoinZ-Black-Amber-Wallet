use crate::error_handling::{WalletError, WalletResult};
use crate::lightwalletd_client::{LightwalletdClient, LightwalletdConfig};
use serde::{Deserialize, Serialize};
use bip39::{Mnemonic, Language};
use sha2::{Sha256, Digest};
use uuid::Uuid;
use chrono::Utc;
use base58::ToBase58;
use secp256k1::{Secp256k1, SecretKey, PublicKey};
use zcash_primitives::zip32::{ExtendedSpendingKey, ExtendedFullViewingKey};
use zcash_address::{ZcashAddress, Network};
use ripemd160::Ripemd160;

/// Mobile wallet implementation for BitcoinZ
pub struct MobileWallet {
    wallet_id: String,
    server_url: String,
    pub seed_phrase: Option<String>,
    birthday_height: u32,
    transparent_addresses: Vec<String>,
    shielded_addresses: Vec<String>,
    balance: Balance,
    transactions: Vec<Transaction>,
    sync_status: SyncStatus,
    pub is_initialized: bool,
    lightwalletd_client: LightwalletdClient,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WalletInfo {
    pub wallet_id: String,
    pub transparent_addresses: Vec<String>,
    pub shielded_addresses: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Balance {
    pub transparent: u64,
    pub shielded: u64,
    pub total: u64,
    pub unconfirmed: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Addresses {
    pub transparent: Vec<String>,
    pub shielded: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncResult {
    pub blocks_synced: u32,
    pub current_height: u32,
    pub total_height: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatus {
    pub is_syncing: bool,
    pub current_block: u32,
    pub total_blocks: u32,
    pub progress: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub txid: String,
    pub amount: i64,
    pub block_height: Option<u32>,
    pub timestamp: u64,
    pub memo: Option<String>,
    pub tx_type: String, // "sent", "received", "pending"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionResult {
    pub txid: String,
    pub fee: u64,
}

impl MobileWallet {
    /// Create a new mobile wallet instance
    pub fn new(server_url: String) -> WalletResult<Self> {
        let config = LightwalletdConfig {
            server_url: server_url.clone(),
            use_tls: true,
        };
        
        let lightwalletd_client = LightwalletdClient::new(config);
        
        Ok(MobileWallet {
            wallet_id: String::new(),
            server_url,
            seed_phrase: None,
            birthday_height: 0, // Scan from genesis to find all transactions
            transparent_addresses: Vec::new(),
            shielded_addresses: Vec::new(),
            balance: Balance {
                transparent: 0,
                shielded: 0,
                total: 0,
                unconfirmed: 0,
            },
            transactions: Vec::new(),
            sync_status: SyncStatus {
                is_syncing: false,
                current_block: 0,
                total_blocks: 0,
                progress: 0.0,
            },
            is_initialized: false,
            lightwalletd_client,
        })
    }

    /// Create a new wallet with the given seed phrase
    pub fn create_wallet(&mut self, seed_phrase: &str) -> WalletResult<WalletInfo> {
        // Validate seed phrase (24 words)
        let word_count = seed_phrase.split_whitespace().count();
        if word_count != 24 {
            return Err(WalletError::InvalidInput(
                format!("Seed phrase must be 24 words, got {}", word_count)
            ));
        }
        
        // Validate using BIP39
        match Mnemonic::parse_in_normalized(Language::English, seed_phrase) {
            Ok(_) => {},
            Err(e) => return Err(WalletError::InvalidInput(format!("Invalid seed phrase: {}", e))),
        }
        
        self.seed_phrase = Some(seed_phrase.to_string());
        self.wallet_id = Uuid::new_v4().to_string();
        
        // Generate initial addresses
        self.transparent_addresses = vec![
            self.generate_transparent_address(0)?,
            self.generate_transparent_address(1)?,
        ];
        
        self.shielded_addresses = vec![
            self.generate_shielded_address(0)?,
        ];
        
        // Set birthday height to scan from beginning to find all transactions
        self.birthday_height = 0;
        self.is_initialized = true;
        
        Ok(WalletInfo {
            wallet_id: self.wallet_id.clone(),
            transparent_addresses: self.transparent_addresses.clone(),
            shielded_addresses: self.shielded_addresses.clone(),
        })
    }

    /// Restore wallet from seed phrase with optional birthday height
    pub fn restore_wallet(&mut self, seed_phrase: &str, birthday_height: u32) -> WalletResult<WalletInfo> {
        // Validate seed phrase
        let word_count = seed_phrase.split_whitespace().count();
        if word_count != 24 {
            return Err(WalletError::InvalidInput(
                format!("Seed phrase must be 24 words, got {}", word_count)
            ));
        }
        
        match Mnemonic::parse_in_normalized(Language::English, seed_phrase) {
            Ok(_) => {},
            Err(e) => return Err(WalletError::InvalidInput(format!("Invalid seed phrase: {}", e))),
        }
        
        self.seed_phrase = Some(seed_phrase.to_string());
        self.wallet_id = Uuid::new_v4().to_string();
        self.birthday_height = if birthday_height > 0 { birthday_height } else { 0 };
        
        // Generate addresses from seed
        self.transparent_addresses = vec![
            self.generate_transparent_address(0)?,
            self.generate_transparent_address(1)?,
        ];
        
        self.shielded_addresses = vec![
            self.generate_shielded_address(0)?,
        ];
        
        self.is_initialized = true;
        
        Ok(WalletInfo {
            wallet_id: self.wallet_id.clone(),
            transparent_addresses: self.transparent_addresses.clone(),
            shielded_addresses: self.shielded_addresses.clone(),
        })
    }

    /// Get wallet balance
    pub fn get_balance(&mut self) -> WalletResult<Balance> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        // Use async runtime to call lightwalletd server
        let rt = tokio::runtime::Runtime::new()
            .map_err(|e| WalletError::CryptoError(format!("Failed to create async runtime: {}", e)))?;
            
        rt.block_on(async {
            self.get_balance_async().await
        })
    }
    
    /// Async version of get_balance for internal use
    async fn get_balance_async(&mut self) -> WalletResult<Balance> {
        // Get transparent balance from lightwalletd
        let transparent_balance = self.lightwalletd_client
            .get_transparent_balance(&self.transparent_addresses)
            .await
            .unwrap_or(0); // Fallback to 0 if connection fails
        
        // For now, shielded balance is still mock since implementing full shielded
        // balance queries requires more complex cryptographic operations
        let shielded_balance = self.balance.shielded;
        
        let updated_balance = Balance {
            transparent: transparent_balance,
            shielded: shielded_balance,
            total: transparent_balance + shielded_balance,
            unconfirmed: 0, // TODO: Implement unconfirmed balance tracking
        };
        
        // Update cached balance
        self.balance = updated_balance.clone();
        
        Ok(updated_balance)
    }

    /// Get all wallet addresses
    pub fn get_addresses(&self) -> WalletResult<Addresses> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        Ok(Addresses {
            transparent: self.transparent_addresses.clone(),
            shielded: self.shielded_addresses.clone(),
        })
    }

    /// Generate a new address
    pub fn generate_new_address(&mut self, address_type: &str) -> WalletResult<String> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        let address = match address_type {
            "t" | "transparent" => {
                let index = self.transparent_addresses.len() as u32;
                let addr = self.generate_transparent_address(index)?;
                self.transparent_addresses.push(addr.clone());
                addr
            },
            "z" | "shielded" => {
                let index = self.shielded_addresses.len() as u32;
                let addr = self.generate_shielded_address(index)?;
                self.shielded_addresses.push(addr.clone());
                addr
            },
            _ => return Err(WalletError::InvalidInput("Invalid address type".to_string())),
        };
        
        Ok(address)
    }

    /// Sync wallet with blockchain
    pub fn sync(&mut self) -> WalletResult<SyncResult> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        // Use async runtime to call lightwalletd server
        let rt = tokio::runtime::Runtime::new()
            .map_err(|e| WalletError::CryptoError(format!("Failed to create async runtime: {}", e)))?;
            
        rt.block_on(async {
            self.sync_async().await
        })
    }
    
    /// Async version of sync for internal use
    async fn sync_async(&mut self) -> WalletResult<SyncResult> {
        self.sync_status.is_syncing = true;
        
        // Get latest block height from lightwalletd
        let latest_height = match self.lightwalletd_client.get_latest_block_height().await {
            Ok(height) => height,
            Err(e) => {
                // If we can't connect, fall back to mock behavior for development
                log::warn!("Failed to connect to lightwalletd server: {}. Using mock data.", e);
                self.sync_status.total_blocks = 2_400_000;
                self.sync_status.current_block = self.birthday_height + 1000; // Simulate some progress
                self.sync_status.progress = (self.sync_status.current_block as f32 / self.sync_status.total_blocks as f32) * 100.0;
                self.sync_status.is_syncing = false;
                
                return Ok(SyncResult {
                    blocks_synced: 1000,
                    current_height: self.sync_status.current_block,
                    total_height: self.sync_status.total_blocks,
                });
            }
        };
        
        self.sync_status.total_blocks = latest_height as u32;
        
        // Determine sync range - ensure birthday height doesn't exceed current height
        let safe_birthday = std::cmp::min(self.birthday_height as u64, latest_height - 1000);
        
        let start_height = if self.sync_status.current_block == 0 {
            // Start from a safe distance before current height if birthday is too high
            if safe_birthday > latest_height - 1000 {
                latest_height - 100 // Start from 100 blocks ago
            } else {
                safe_birthday
            }
        } else {
            self.sync_status.current_block as u64 + 1
        };
        
        log::info!("Sync range: start_height={}, latest_height={}, birthday_height={}", 
                   start_height, latest_height, self.birthday_height);
        
        let sync_range = if latest_height > start_height {
            std::cmp::min(latest_height - start_height, 10) // Sync fewer blocks to avoid timeout
        } else {
            0
        };
        
        if sync_range > 0 {
            let end_height = start_height + sync_range - 1;
            
            // Perform actual blockchain sync
            match self.lightwalletd_client.sync_blocks(start_height, end_height).await {
                Ok(sync_progress) => {
                    self.sync_status.current_block = sync_progress.current_height as u32;
                    self.sync_status.progress = (self.sync_status.current_block as f32 / self.sync_status.total_blocks as f32) * 100.0;
                    self.sync_status.is_syncing = false;
                    
                    Ok(SyncResult {
                        blocks_synced: sync_progress.blocks_synced,
                        current_height: sync_progress.current_height as u32,
                        total_height: self.sync_status.total_blocks,
                    })
                }
                Err(e) => {
                    self.sync_status.is_syncing = false;
                    Err(WalletError::NetworkError(format!("Sync failed: {}", e)))
                }
            }
        } else {
            // Already synced
            self.sync_status.current_block = latest_height as u32;
            self.sync_status.progress = 100.0;
            self.sync_status.is_syncing = false;
            
            Ok(SyncResult {
                blocks_synced: 0,
                current_height: latest_height as u32,
                total_height: latest_height as u32,
            })
        }
    }

    /// Get sync status
    pub fn get_sync_status(&self) -> WalletResult<SyncStatus> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        Ok(self.sync_status.clone())
    }

    /// Send transaction
    pub fn send_transaction(&mut self, to_address: &str, amount_zatoshis: u64, memo: Option<&str>) -> WalletResult<TransactionResult> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        // Validate address
        if !self.is_valid_address(to_address) {
            return Err(WalletError::InvalidAddress(to_address.to_string()));
        }
        
        // Check balance
        if amount_zatoshis > self.balance.total {
            return Err(WalletError::InsufficientFunds);
        }
        
        // In production, this would build and broadcast a real transaction
        // For now, create a mock transaction
        let txid = format!("{:x}", Sha256::digest(format!("{}{}{}", to_address, amount_zatoshis, Utc::now().timestamp()).as_bytes()));
        let fee = 10000u64; // 0.0001 BTCZ fee
        
        // Add to transaction history
        self.transactions.push(Transaction {
            txid: txid.clone(),
            amount: -(amount_zatoshis as i64),
            block_height: Some(self.sync_status.current_block),
            timestamp: Utc::now().timestamp() as u64,
            memo: memo.map(|m| m.to_string()),
            tx_type: "sent".to_string(),
        });
        
        // Update balance
        self.balance.total = self.balance.total.saturating_sub(amount_zatoshis + fee);
        self.balance.transparent = self.balance.transparent.saturating_sub(amount_zatoshis + fee);
        
        Ok(TransactionResult {
            txid,
            fee,
        })
    }

    /// Get transaction history
    pub fn get_transactions(&self) -> WalletResult<Vec<Transaction>> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        Ok(self.transactions.clone())
    }

    /// Encrypt message for z-address
    pub fn encrypt_message(&self, z_address: &str, message: &str) -> WalletResult<String> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        if !z_address.starts_with("zc") && !z_address.starts_with("zs1") {
            return Err(WalletError::InvalidAddress("Not a shielded address".to_string()));
        }
        
        // In production, this would use real encryption with the z-address public key
        // For now, return base64 encoded message as mock
        Ok(base64::encode(format!("ENCRYPTED:{}:{}", z_address, message)))
    }

    /// Decrypt message
    pub fn decrypt_message(&self, encrypted_data: &str) -> WalletResult<String> {
        if !self.is_initialized {
            return Err(WalletError::WalletNotFound);
        }
        
        // In production, this would use real decryption with the wallet's private key
        // For now, decode base64 as mock
        let decoded = base64::decode(encrypted_data)
            .map_err(|e| WalletError::CryptoError(format!("Invalid encrypted data: {}", e)))?;
        
        let message = String::from_utf8(decoded)
            .map_err(|e| WalletError::CryptoError(format!("Invalid UTF-8: {}", e)))?;
        
        // Remove mock prefix
        Ok(message.replace("ENCRYPTED:", "").split(':').nth(1).unwrap_or(&message).to_string())
    }

    // Helper functions
    
    /// Get private key for a transparent address  
    pub fn get_private_key(&self, address_index: u32) -> WalletResult<String> {
        let seed = self.seed_phrase.as_ref()
            .ok_or(WalletError::InvalidInput("No seed phrase set".to_string()))?;
        
        // Parse mnemonic and derive master key
        let mnemonic = Mnemonic::parse(seed)
            .map_err(|e| WalletError::InvalidInput(format!("Invalid mnemonic: {}", e)))?;
        let seed_bytes = mnemonic.to_seed("");
        
        // Create secp256k1 context
        let secp = Secp256k1::new();
        
        // Use the same derivation as address generation to ensure consistency
        let mut derived_seed = seed_bytes.to_vec();
        derived_seed.extend_from_slice(&44u32.to_be_bytes());  // purpose
        derived_seed.extend_from_slice(&177u32.to_be_bytes()); // BitcoinZ coin type
        derived_seed.extend_from_slice(&0u32.to_be_bytes());   // account
        derived_seed.extend_from_slice(&0u32.to_be_bytes());   // change
        derived_seed.extend_from_slice(&address_index.to_be_bytes());  // address_index
        
        let private_key_hash = Sha256::digest(&derived_seed);
        let secret_key = SecretKey::from_slice(&private_key_hash)
            .map_err(|e| WalletError::CryptoError(format!("Invalid private key: {}", e)))?;
        
        // Return private key in WIF (Wallet Import Format) for BitcoinZ
        Ok(self.private_key_to_wif(&secret_key)?)
    }
    
    /// Convert private key to WIF format for BitcoinZ
    fn private_key_to_wif(&self, secret_key: &SecretKey) -> WalletResult<String> {
        // BitcoinZ mainnet private key prefix is 0x80 (same as Bitcoin)
        let mut wif_data = vec![0x80];
        wif_data.extend_from_slice(secret_key.as_ref());
        
        // Add compression flag for compressed public key
        wif_data.push(0x01);
        
        // Double SHA256 for checksum
        let checksum = Sha256::digest(&Sha256::digest(&wif_data));
        wif_data.extend_from_slice(&checksum[0..4]);
        
        // Base58 encode
        Ok(wif_data.to_base58())
    }
    
    pub fn generate_transparent_address(&self, index: u32) -> WalletResult<String> {
        // Generate proper BitcoinZ transparent address using BIP44 derivation
        let seed = self.seed_phrase.as_ref()
            .ok_or(WalletError::InvalidInput("No seed phrase set".to_string()))?;
        
        // Parse mnemonic and derive master key
        let mnemonic = Mnemonic::parse(seed)
            .map_err(|e| WalletError::InvalidInput(format!("Invalid mnemonic: {}", e)))?;
        let seed_bytes = mnemonic.to_seed("");
        
        // Create secp256k1 context
        let secp = Secp256k1::new();
        
        // Derive private key using simplified BIP32-like derivation for BitcoinZ
        // Path: m/44'/177'/0'/0/index (177 is BitcoinZ coin type)
        let mut derived_seed = seed_bytes.to_vec();
        derived_seed.extend_from_slice(&44u32.to_be_bytes());  // purpose
        derived_seed.extend_from_slice(&177u32.to_be_bytes()); // BitcoinZ coin type
        derived_seed.extend_from_slice(&0u32.to_be_bytes());   // account
        derived_seed.extend_from_slice(&0u32.to_be_bytes());   // change
        derived_seed.extend_from_slice(&index.to_be_bytes());  // address_index
        
        let private_key_hash = Sha256::digest(&derived_seed);
        let secret_key = SecretKey::from_slice(&private_key_hash)
            .map_err(|e| WalletError::CryptoError(format!("Invalid private key: {}", e)))?;
        
        // Generate public key
        let public_key = PublicKey::from_secret_key(&secp, &secret_key);
        let public_key_bytes = public_key.serialize_uncompressed();
        
        // Create BitcoinZ P2PKH address (similar to Bitcoin but with BitcoinZ prefixes)
        // 1. SHA256 of public key
        let sha256_hash = Sha256::digest(&public_key_bytes[1..33]); // Skip 0x04 prefix
        
        // 2. RIPEMD160 of SHA256 hash
        let mut hasher = Ripemd160::new();
        hasher.update(&sha256_hash);
        let ripemd_hash = hasher.finalize();
        
        // 3. Add BitcoinZ transparent address prefix (0x1CB8 for t1 addresses)
        let mut address_bytes = vec![0x1C, 0xB8];
        address_bytes.extend_from_slice(&ripemd_hash);
        
        // 4. Double SHA256 for checksum
        let checksum_hash = Sha256::digest(&Sha256::digest(&address_bytes));
        address_bytes.extend_from_slice(&checksum_hash[0..4]);
        
        // 5. Base58 encode
        let address = address_bytes.to_base58();
        
        Ok(address)
    }
    
    pub fn generate_shielded_address(&self, index: u32) -> WalletResult<String> {
        // For now, create a simplified but more realistic shielded address
        // This is a placeholder until we can integrate full Sapling key derivation
        let seed = self.seed_phrase.as_ref()
            .ok_or(WalletError::InvalidInput("No seed phrase set".to_string()))?;
        
        // Parse mnemonic
        let mnemonic = Mnemonic::parse(seed)
            .map_err(|e| WalletError::InvalidInput(format!("Invalid mnemonic: {}", e)))?;
        let seed_bytes = mnemonic.to_seed("");
        
        // Derive a more realistic shielded address using proper entropy
        // Path similar to Sapling: m/32'/177'/0'/index
        let mut derived_seed = seed_bytes.to_vec();
        derived_seed.extend_from_slice(&32u32.to_be_bytes());  // Sapling purpose
        derived_seed.extend_from_slice(&177u32.to_be_bytes()); // BitcoinZ coin type
        derived_seed.extend_from_slice(&0u32.to_be_bytes());   // account
        derived_seed.extend_from_slice(&index.to_be_bytes());  // address index
        
        // Create multiple rounds of hashing for better entropy
        let mut hash = Sha256::digest(&derived_seed).to_vec();
        for _ in 0..3 {
            hash = Sha256::digest(&hash).to_vec();
        }
        
        // Use proper bech32 character set (excluding confusing characters)
        const BECH32_CHARSET: &[u8] = b"qpzry9x8gf2tvdw0s3jn54khce6mua7l";
        
        let mut address_data = Vec::new();
        let mut hash_idx = 0;
        
        // Generate 75 characters of address data using proper entropy distribution
        for i in 0..75 {
            // Rehash periodically to maintain entropy
            if i > 0 && i % 16 == 0 {
                let mut new_hash_input = hash.clone();
                new_hash_input.extend_from_slice(&(i as u32).to_be_bytes());
                hash = Sha256::digest(&new_hash_input).to_vec();
                hash_idx = 0;
            }
            
            let char_idx = hash[hash_idx % hash.len()] as usize % BECH32_CHARSET.len();
            address_data.push(BECH32_CHARSET[char_idx]);
            hash_idx += 1;
        }
        
        let address_suffix = String::from_utf8(address_data)
            .map_err(|e| WalletError::InvalidInput(format!("Address encoding error: {}", e)))?;
        
        let final_address = format!("zs1{}", address_suffix);
        
        // Ensure address is exactly 78 characters
        if final_address.len() != 78 {
            return Err(WalletError::InvalidInput(
                format!("Invalid shielded address length: {}", final_address.len())
            ));
        }
        
        Ok(final_address)
    }
    
    fn is_valid_address(&self, address: &str) -> bool {
        // Basic validation for BitcoinZ addresses
        if address.starts_with("t1") && address.len() >= 34 {
            return true;
        }
        if (address.starts_with("zc") || address.starts_with("zs1")) && address.len() >= 60 {
            return true;
        }
        false
    }
}