@echo off
REM Setup native assets for Windows Flutter build
REM This ensures the Rust DLL is in the correct location for bundling

echo 🔧 Setting up native assets for Windows Flutter build...

REM Create native_assets directory for Windows
if not exist "build\native_assets\windows" (
    mkdir "build\native_assets\windows"
    echo 📁 Created build\native_assets\windows directory
)

REM Copy DLL from windows directory if it exists
if exist "windows\bitcoinz_wallet_rust.dll" (
    copy /Y "windows\bitcoinz_wallet_rust.dll" "build\native_assets\windows\"
    echo ✅ Copied bitcoinz_wallet_rust.dll to native_assets
) else (
    echo ⚠️  DLL not found in windows\ directory
)

REM Also copy from rust target directory if it exists
if exist "rust\target\x86_64-pc-windows-msvc\release\bitcoinz_wallet_rust.dll" (
    copy /Y "rust\target\x86_64-pc-windows-msvc\release\bitcoinz_wallet_rust.dll" "build\native_assets\windows\"
    echo ✅ Copied DLL from Rust target to native_assets
)

REM Verify the DLL is in place
if exist "build\native_assets\windows\bitcoinz_wallet_rust.dll" (
    echo 📊 DLL size in native_assets:
    dir "build\native_assets\windows\bitcoinz_wallet_rust.dll"
    echo ✅ Native assets setup complete for Windows!
) else (
    echo ❌ ERROR: bitcoinz_wallet_rust.dll not found in native_assets!
    echo Please ensure the Rust library was built successfully.
    exit /b 1
)