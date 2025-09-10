@echo off
REM BitcoinZ Mobile Wallet - Windows Rust Build Script
REM Builds Rust library for Windows x86_64

echo 🪟 Building Rust libraries for Windows...

REM Navigate to Rust project
cd rust

REM Windows target
set TARGET=x86_64-pc-windows-msvc

REM Windows library output directory (for Flutter Windows)
set WINDOWS_LIBS_DIR=..\windows
if not exist "%WINDOWS_LIBS_DIR%" mkdir "%WINDOWS_LIBS_DIR%"

echo 🔨 Building for Windows target: %TARGET%...

REM Clean previous build
cargo clean --target %TARGET%

REM Build with release optimizations
cargo build --release --target %TARGET%

echo 📦 Copying libraries to Flutter Windows directory...

REM Copy DLL for Flutter Windows
copy "target\%TARGET%\release\bitcoinz_wallet_rust.dll" "%WINDOWS_LIBS_DIR%\"
if errorlevel 1 (
    echo ❌ Failed to copy DLL
    exit /b 1
)

REM Copy static library (may be needed)
copy "target\%TARGET%\release\bitcoinz_wallet_rust.lib" "%WINDOWS_LIBS_DIR%\"
if errorlevel 1 (
    echo ❌ Failed to copy LIB
    exit /b 1
)

echo 🎉 Windows Rust build completed!
echo 📁 Libraries copied to: %WINDOWS_LIBS_DIR%\

REM Display library info
echo 📊 Library files:
dir /s "%WINDOWS_LIBS_DIR%\bitcoinz_wallet_rust.*"

echo ✅ Windows build successful!