use std::fmt;

#[derive(Debug)]
pub enum WalletError {
    InvalidInput(String),
    NetworkError(String),
    CryptoError(String),
    WalletNotFound,
    InsufficientFunds,
    InvalidAddress(String),
    SyncError(String),
    TransactionError(String),
    SerializationError(String),
    IoError(String),
}

impl fmt::Display for WalletError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            WalletError::InvalidInput(msg) => write!(f, "Invalid input: {}", msg),
            WalletError::NetworkError(msg) => write!(f, "Network error: {}", msg),
            WalletError::CryptoError(msg) => write!(f, "Cryptographic error: {}", msg),
            WalletError::WalletNotFound => write!(f, "Wallet not found"),
            WalletError::InsufficientFunds => write!(f, "Insufficient funds"),
            WalletError::InvalidAddress(addr) => write!(f, "Invalid address: {}", addr),
            WalletError::SyncError(msg) => write!(f, "Sync error: {}", msg),
            WalletError::TransactionError(msg) => write!(f, "Transaction error: {}", msg),
            WalletError::SerializationError(msg) => write!(f, "Serialization error: {}", msg),
            WalletError::IoError(msg) => write!(f, "IO error: {}", msg),
        }
    }
}

impl std::error::Error for WalletError {}

impl From<std::io::Error> for WalletError {
    fn from(error: std::io::Error) -> Self {
        WalletError::IoError(error.to_string())
    }
}

impl From<serde_json::Error> for WalletError {
    fn from(error: serde_json::Error) -> Self {
        WalletError::SerializationError(error.to_string())
    }
}

impl From<tonic::Status> for WalletError {
    fn from(error: tonic::Status) -> Self {
        WalletError::NetworkError(error.to_string())
    }
}

pub type WalletResult<T> = Result<T, WalletError>;