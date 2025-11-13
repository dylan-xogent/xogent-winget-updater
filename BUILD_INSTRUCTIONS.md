# Build Instructions - XOGENT Winget Auto-Updater

**Copyright © XOGENT, INC 2024**

## Prerequisites

Before building, you need to install the following:

### 1. .NET 8.0 SDK
- **Download**: https://dotnet.microsoft.com/download/dotnet/8.0
- **Install**: Run the installer and follow the prompts
- **Verify**: Open a new PowerShell/Command Prompt and run `dotnet --version`

### 2. WiX Toolset v3.11 or later
- **Download**: https://wixtoolset.org/releases/
- **Install**: Run the installer
- **Verify**: Open a new PowerShell/Command Prompt and run `candle -?`

## Building

### Option 1: Using the Build Script (Recommended)

Simply run:
```powershell
.\build.ps1
```

Or on Windows:
```cmd
build.bat
```

The script will:
1. Check for prerequisites
2. Build the application
3. Build the MSI installer
4. Show you where the output files are located

### Option 2: Manual Build

#### Build the Application
```powershell
cd WingetUpdater
dotnet restore
dotnet build -c Release
```

#### Build the MSI Installer
```powershell
cd Installer
candle Product.wxs -ext WixUtilExtension
light Product.wixobj -ext WixUtilExtension -out XogentWingetUpdater.msi
```

**Note**: You'll need to update the `Source` path in `Product.wxs` to point to the built executable:
`WingetUpdater\bin\Release\net8.0-windows\XogentWingetUpdater.exe`

## Output Locations

After building:
- **Application**: `WingetUpdater\bin\Release\net8.0-windows\XogentWingetUpdater.exe`
- **MSI Installer**: `Installer\bin\Release\XogentWingetUpdater.msi`
- Application will be installed to: `C:\Program Files\XOGENT\WingetUpdater\`

## Troubleshooting

### "dotnet is not recognized"
- Install .NET 8.0 SDK (see Prerequisites above)
- Close and reopen your terminal/PowerShell window
- Verify installation: `dotnet --version`

### "candle is not recognized"
- Install WiX Toolset (see Prerequisites above)
- Close and reopen your terminal/PowerShell window
- Verify installation: `candle -?`

### Build Errors
- Ensure you're in the project root directory
- Run `dotnet restore` before building
- Check that all files are present (no missing files)

