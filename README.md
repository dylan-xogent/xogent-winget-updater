# XOGENT Winget Auto-Updater

<div align="center">

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A modern, enterprise-ready Windows application that automatically updates all software via winget on system boot.**

Features a beautiful GUI, seamless RMM deployment, comprehensive logging, and zero user interaction required.

**Developed by XOGENT, INC** - Security, Compliance, and Managed IT Services
📞 (678) 208-8866 | 🌐 [www.xogent.com](https://www.xogent.com)

</div>

---

## 📋 Table of Contents

- [Features](#-features)
- [Screenshots](#-screenshots)
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
  - [End User Installation](#end-user-installation)
  - [IT Admin Deployment](#it-admin-deployment)
  - [NinjaRMM Deployment](#ninjarmm-deployment)
- [Building from Source](#-building-from-source)
- [Deployment Scripts](#-deployment-scripts)
- [Customization Guide](#-customization-guide)
- [Project Structure](#-project-structure)
- [Usage](#-usage)
- [Troubleshooting](#-troubleshooting)
- [Technical Details](#-technical-details)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)

---

## ✨ Features

- **🔄 Automatic Updates**: Runs on every Windows boot/reboot to update all winget-managed software
- **🎨 Modern GUI**: Beautiful gradient-based interface with real-time progress, animations, and package tracking
- **⚡ Zero Interaction**: Fully automated - runs silently and closes without user input
- **📊 Comprehensive Logging**: All operations logged with timestamps to `%LOCALAPPDATA%\XOGENT\WingetUpdater\logs\`
- **🚀 Fast Performance**: Optimized for quick execution with minimal overhead
- **🏢 Enterprise Ready**: MSI installer with PowerShell deployment scripts for NinjaRMM and other RMM tools
- **📦 Easy Deployment**: Silent installation, scheduled task automation, and remote management support
- **🔧 Customizable**: Complete source code with guides to rebrand for your own organization

---

## 📸 Screenshots

<div align="center">

*Modern GUI with real-time progress tracking, rotating status icon, and professional branding*

</div>

---

## 📋 Requirements

### Runtime Requirements
- **Operating System**: Windows 10 or Windows 11
- **.NET Runtime**: .NET 8.0 Desktop Runtime
  - ✅ Included in Windows 11
  - 📥 [Download for Windows 10](https://dotnet.microsoft.com/download/dotnet/8.0)
- **Winget**: Windows Package Manager (App Installer)
  - ✅ Pre-installed on Windows 11
  - 📥 [Download from Microsoft Store](https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1)
- **Permissions**: Administrator privileges for installation

### Build Requirements
- **Development**: .NET 8.0 SDK
- **Installer**: WiX Toolset v3.14 or later
- **IDE** (Optional): Visual Studio 2022 or VS Code

---

## 🚀 Quick Start

### For End Users

1. **Download** the latest `XogentWingetUpdater.msi` from [Releases](../../releases)
2. **Run** the MSI installer (requires administrator)
3. **Reboot** your computer - the updater will run automatically on every boot
4. **Check logs** (optional) at `%LOCALAPPDATA%\XOGENT\WingetUpdater\logs\`

### For IT Administrators

See the complete [NinjaRMM Deployment Guide](Deploy/NINJARMM_DEPLOYMENT.md) for enterprise deployment with PowerShell scripts.

---

## 📦 Installation

### End User Installation

1. **Download MSI**: Get the latest `XogentWingetUpdater.msi` installer
2. **Run Installer**: Double-click the MSI file (requires administrator)
3. **Complete Setup**: Follow the installation wizard
4. **Automatic Configuration**:
   - Installs to `C:\Program Files\XOGENT\WingetUpdater\`
   - Creates scheduled task "XogentWingetUpdater"
   - Configures automatic startup
5. **First Run**: Application runs automatically on next boot/reboot

### IT Admin Deployment

#### Silent Installation
```cmd
msiexec /i XogentWingetUpdater.msi /qn /norestart /L*v "%TEMP%\XogentInstall.log"
```

#### Silent Uninstallation
```cmd
msiexec /x {PRODUCT-GUID} /qn /norestart /L*v "%TEMP%\XogentUninstall.log"
```

*Replace `{PRODUCT-GUID}` with the actual product code from the MSI*

### NinjaRMM Deployment

See the complete [NinjaRMM Deployment Guide](Deploy/NINJARMM_DEPLOYMENT.md) for:
- ✅ Three deployment methods (Software Management, Scripts, PowerShell)
- ✅ Monitoring and verification scripts
- ✅ Custom field creation
- ✅ Troubleshooting procedures
- ✅ Best practices for enterprise rollout

**Quick Deployment with Scripts**:

```powershell
# Installation
.\Deploy\Install-XogentWingetUpdater.ps1

# Verification
.\Deploy\Verify-XogentWingetUpdater.ps1 -Detailed

# Uninstallation
.\Deploy\Uninstall-XogentWingetUpdater.ps1
```

---

## 🔨 Building from Source

### Prerequisites

1. **Install .NET 8.0 SDK**
   ```bash
   # Download from: https://dotnet.microsoft.com/download/dotnet/8.0
   # Or install via winget:
   winget install Microsoft.DotNet.SDK.8
   ```

2. **Install WiX Toolset v3.14**
   ```bash
   # Download from: https://wixtoolset.org/releases/
   # Or the script will auto-download during build
   ```

### Build Steps

#### Option 1: Automated Build (Recommended)

```powershell
# PowerShell
.\build.ps1
```

```cmd
# Command Prompt
build.bat
```

The build script will:
- ✅ Detect and download WiX Toolset if needed
- ✅ Restore NuGet packages
- ✅ Build the .NET application
- ✅ Compile the MSI installer
- ✅ Output to `Output/` directory

#### Option 2: Manual Build

```bash
# 1. Restore dependencies
dotnet restore

# 2. Build application
dotnet build WingetUpdater/WingetUpdater.csproj -c Release

# 3. Publish application
dotnet publish WingetUpdater/WingetUpdater.csproj -c Release -r win-x64 --self-contained false

# 4. Build MSI (requires WiX in PATH)
cd Installer
candle Product.wxs -ext WixUtilExtension -ext WixUIExtension
light Product.wixobj -ext WixUtilExtension -ext WixUIExtension -out XogentWingetUpdater.msi
```

### Build Output

```
Output/
├── XogentWingetUpdater.exe    # Application executable
└── XogentWingetUpdater.msi    # MSI installer
```

---

## 📜 Deployment Scripts

The `Deploy/` directory contains enterprise-ready PowerShell scripts for remote deployment:

### Install-XogentWingetUpdater.ps1

**Purpose**: Silent installation with comprehensive logging and prerequisite checking.

```powershell
# Basic installation
.\Install-XogentWingetUpdater.ps1

# Specify MSI path
.\Install-XogentWingetUpdater.ps1 -MsiPath "\\server\share\XogentWingetUpdater.msi"

# Custom log location
.\Install-XogentWingetUpdater.ps1 -LogPath "C:\Logs\install.log"
```

**Features**:
- ✅ Automatic prerequisite detection (.NET, Winget)
- ✅ Existing version detection and upgrade
- ✅ Scheduled task verification/creation
- ✅ Comprehensive logging
- ✅ Zero user interaction required

**Exit Codes**: `0` = Success, `1` = Error, `3010` = Success (reboot required)

### Uninstall-XogentWingetUpdater.ps1

**Purpose**: Complete removal of application and components.

```powershell
# Basic uninstallation (preserves logs)
.\Uninstall-XogentWingetUpdater.ps1

# Remove logs as well
.\Uninstall-XogentWingetUpdater.ps1 -RemoveLogs

# Custom log location
.\Uninstall-XogentWingetUpdater.ps1 -LogPath "C:\Logs\uninstall.log"
```

**Features**:
- ✅ MSI uninstallation
- ✅ Scheduled task removal
- ✅ File cleanup
- ✅ Optional log file removal

**Exit Codes**: `0` = Success, `1` = Error

### Verify-XogentWingetUpdater.ps1

**Purpose**: Health check and monitoring for RMM platforms.

```powershell
# Basic verification
.\Verify-XogentWingetUpdater.ps1

# Detailed output with log analysis
.\Verify-XogentWingetUpdater.ps1 -Detailed

# Exit with error code if issues found
.\Verify-XogentWingetUpdater.ps1 -ExitOnError
```

**Features**:
- ✅ Installation verification
- ✅ Scheduled task status
- ✅ Prerequisite checking
- ✅ Recent execution analysis
- ✅ Detailed reporting

**Exit Codes**: `0` = All checks passed, `1` = Not installed, `2` = Task issues, `3` = Missing prerequisites, `4` = Recent execution failures

---

## 🎨 Customization Guide

Want to rebrand this for your own company? Follow these steps:

### 1. Company Branding

**Files to modify**:

#### `WingetUpdater/WingetUpdater.csproj`
```xml
<PropertyGroup>
  <ApplicationTitle>YOUR COMPANY Winget Auto-Updater</ApplicationTitle>
  <Authors>YOUR COMPANY, INC</Authors>
  <Company>YOUR COMPANY, INC</Company>
  <Product>YOUR COMPANY Winget Auto-Updater</Product>
  <Copyright>Copyright © YOUR COMPANY, INC 2024</Copyright>
  <Description>YOUR DESCRIPTION HERE</Description>
</PropertyGroup>
```

#### `Installer/Product.wxs`
```xml
<Product Name="YOUR COMPANY Winget Auto-Updater"
         Manufacturer="YOUR COMPANY, INC"
         UpgradeCode="GENERATE-NEW-GUID-HERE">
  <Package Description="YOUR DESCRIPTION - (YOUR-PHONE-NUMBER)"
           Manufacturer="YOUR COMPANY, INC"
           Comments="YOUR COMPANY - YOUR SERVICES - www.yoursite.com"/>
```

**Important**: Generate a new UpgradeCode GUID:
```powershell
[guid]::NewGuid().ToString().ToUpper()
```

#### `WingetUpdater/Services/LoggingService.cs`
```csharp
// Line 16-17: Change log directory path
_logDirectory = Path.Combine(localAppData, "YOUR_COMPANY", "WingetUpdater", "logs");
```

### 2. Installation Paths

**Files to modify**:

#### `Installer/Product.wxs`
```xml
<!-- Change installation directory structure -->
<Directory Id="ProgramFilesFolder">
  <Directory Id="YOURCOMPANYFOLDER" Name="YOURCOMPANY">
    <Directory Id="INSTALLFOLDER" Name="WingetUpdater">
```

#### All PowerShell scripts in `Deploy/`:
- Update paths from `C:\Program Files\XOGENT\` to `C:\Program Files\YOURCOMPANY\`
- Update log paths from `XOGENT\WingetUpdater` to `YOURCOMPANY\WingetUpdater`

### 3. Visual Branding

#### Replace Logo
1. Replace `WingetUpdater/Resources/xogent-logo.png` with your company logo
2. Recommended size: 200-300px wide, transparent background (PNG)

#### Update Colors
Edit `WingetUpdater/MainWindow.xaml`:

```xml
<!-- Find and replace color values -->
<!-- Primary Blue: #1976d2 → YOUR_PRIMARY_COLOR -->
<!-- Secondary Blue: #42a5f5 → YOUR_SECONDARY_COLOR -->
<!-- Light Blue: #90caf9 → YOUR_LIGHT_COLOR -->
```

#### Update Contact Information
Edit `WingetUpdater/MainWindow.xaml`:

```xml
<!-- Footer section -->
<TextBlock Text="YOUR COMPANY, INC"/>
<TextBlock Text="📞 (YOUR-PHONE) | 🌐 www.yoursite.com"/>
<TextBlock Text="YOUR TAGLINE HERE"/>
```

### 4. Deployment Scripts

Update all scripts in `Deploy/`:

- **Company Name**: Replace "XOGENT" with your company name
- **Product Name**: Update "XOGENT Winget Auto-Updater" references
- **Support Info**: Update contact information in documentation
- **File Paths**: Update all hardcoded paths

### 5. Documentation

Update these files:
- `README.md` - Update branding, contact info, links
- `Deploy/NINJARMM_DEPLOYMENT.md` - Update company references
- `BUILD_INSTRUCTIONS.md` - Update any company-specific info

### 6. Build and Test

After customization:

```powershell
# 1. Clean previous builds
Remove-Item -Recurse -Force Output, WingetUpdater/bin, WingetUpdater/obj, Installer/bin, Installer/obj -ErrorAction SilentlyContinue

# 2. Build with new branding
.\build.ps1

# 3. Test installation
msiexec /i Output\YourCompanyWingetUpdater.msi /l*v install.log

# 4. Verify
.\Deploy\Verify-XogentWingetUpdater.ps1 -Detailed
```

### 7. Version Control

Don't forget to update:
- Version numbers in `Installer/Product.wxs`
- Copyright years
- Changelog/release notes

---

## 📁 Project Structure

```
xogent-winget-updater/
├── WingetUpdater/              # Main application source
│   ├── MainWindow.xaml         # UI layout and styling
│   ├── MainWindow.xaml.cs      # UI logic and winget execution
│   ├── App.xaml                # Application configuration
│   ├── WingetUpdater.csproj    # Project file
│   ├── Resources/              # Images and assets
│   │   ├── xogent-logo.png     # Company logo
│   │   └── Styles.xaml         # Shared styles
│   └── Services/               # Business logic
│       └── LoggingService.cs   # Logging functionality
│
├── Installer/                  # WiX installer project
│   ├── Product.wxs             # MSI installer definition
│   └── Installer.wixproj       # WiX project file
│
├── Deploy/                     # Enterprise deployment scripts
│   ├── Install-XogentWingetUpdater.ps1    # Silent installation
│   ├── Uninstall-XogentWingetUpdater.ps1  # Complete removal
│   ├── Verify-XogentWingetUpdater.ps1     # Health check
│   └── NINJARMM_DEPLOYMENT.md             # Complete deployment guide
│
├── Output/                     # Build output (generated)
│   ├── XogentWingetUpdater.exe
│   └── XogentWingetUpdater.msi
│
├── build.ps1                   # PowerShell build script
├── build.bat                   # Batch build script
├── README.md                   # This file
├── BUILD_INSTRUCTIONS.md       # Detailed build guide
└── .gitignore                  # Git ignore rules
```

---

## 💻 Usage

### Automatic Execution

The application runs automatically on every Windows boot/reboot. **No user interaction required.**

### Manual Execution

If you need to run the updater manually:

1. Navigate to: `C:\Program Files\XOGENT\WingetUpdater\`
2. Run: `XogentWingetUpdater.exe`
3. The GUI will appear, show real-time progress, and close automatically when complete

### Monitoring Logs

**Log Location**: `%LOCALAPPDATA%\XOGENT\WingetUpdater\logs\`

**Log Format**: `updater-YYYY-MM-DD-HHMMSS.log`

**Log Contents**:
- ⏰ Timestamp of each operation
- 📦 List of packages being updated
- ✅ Success/failure counts
- ⚡ Duration of update process
- ❌ Error messages and stack traces (if any)
- 📊 Winget command output

**Example Log Entry**:
```
[2024-01-15 08:32:15] Starting XOGENT Winget Auto-Updater
[2024-01-15 08:32:16] Executing: winget upgrade --all --silent --accept-source-agreements --accept-package-agreements
[2024-01-15 08:32:45] Successfully updated: Microsoft.VisualStudioCode
[2024-01-15 08:32:46] Successfully updated: Google.Chrome
[2024-01-15 08:33:12] Update process completed: 12 successful, 0 failed
[2024-01-15 08:33:12] Total duration: 57 seconds
```

### Scheduled Task Management

**View Task**:
```cmd
schtasks /query /tn "XogentWingetUpdater" /fo LIST /v
```

**Run Manually**:
```cmd
schtasks /run /tn "XogentWingetUpdater"
```

**Disable (without uninstalling)**:
```cmd
schtasks /change /tn "XogentWingetUpdater" /disable
```

**Enable**:
```cmd
schtasks /change /tn "XogentWingetUpdater" /enable
```

---

## 🔧 Troubleshooting

### Application Doesn't Run on Boot

**Check if scheduled task exists**:
```cmd
schtasks /query /tn "XogentWingetUpdater"
```

**If missing, recreate manually**:
```cmd
schtasks /Create /TN "XogentWingetUpdater" /TR "C:\Program Files\XOGENT\WingetUpdater\XogentWingetUpdater.exe" /SC ONSTART /RL HIGHEST /F
```

**Verify task configuration**:
```powershell
Get-ScheduledTask -TaskName "XogentWingetUpdater" | Get-ScheduledTaskInfo
```

### Winget Not Found Error

**Check if winget is installed**:
```cmd
winget --version
```

**Install App Installer** (if missing):
- Windows 11: Should be pre-installed
- Windows 10: [Download from Microsoft Store](https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1)

**Alternative installation**:
```powershell
# Download and install App Installer via PowerShell
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
```

### .NET Runtime Not Found

**Check installed runtimes**:
```cmd
dotnet --list-runtimes
```

**Install .NET 8.0 Desktop Runtime**:
- Windows 11: Usually pre-installed
- Windows 10: [Download from Microsoft](https://dotnet.microsoft.com/download/dotnet/8.0)

**Or via winget**:
```cmd
winget install Microsoft.DotNet.DesktopRuntime.8
```

### Updates Not Applying

**Common causes**:
1. **Permissions**: Some packages require elevation
2. **Package Conflicts**: Manually installed software may conflict
3. **Package Limitations**: Some software doesn't support silent updates

**Check logs**:
```powershell
# View most recent log
$logDir = "$env:LOCALAPPDATA\XOGENT\WingetUpdater\logs"
Get-ChildItem $logDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

### MSI Installation Fails

**Check MSI log**:
```cmd
msiexec /i XogentWingetUpdater.msi /l*v install.log
notepad install.log
```

**Common issues**:
- Insufficient permissions (must run as administrator)
- Previous version not fully uninstalled
- .NET 8.0 Runtime not installed

### Scheduled Task Runs But Application Doesn't Update

**Possible causes**:
1. **User context**: Task runs as SYSTEM but winget needs user context
2. **Path issues**: Winget not in SYSTEM's PATH

**Solution**: Ensure task runs with user privileges:
```powershell
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
```

---

## 🔬 Technical Details

### Architecture

- **Framework**: .NET 8.0 WPF (Windows Presentation Foundation)
- **Language**: C# 12
- **UI**: XAML with Material Design-inspired styling
- **Installer**: WiX Toolset v3.14
- **Automation**: Windows Task Scheduler
- **Package Manager**: Windows Package Manager (winget)

### Scheduled Task Configuration

| Property | Value |
|----------|-------|
| **Task Name** | XogentWingetUpdater |
| **Trigger** | At system startup |
| **Run Level** | Highest privileges |
| **User Context** | SYSTEM account |
| **Allow on Batteries** | Yes |
| **Wake to Run** | No |

### Performance Metrics

- **Startup Time**: < 100ms
- **UI Initialization**: < 200ms
- **Update Duration**: Varies by packages (typically 30-120 seconds)
- **Memory Usage**: ~30-50 MB during execution
- **CPU Usage**: Low (mostly waiting on winget)

### Winget Command Execution

```bash
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements
```

**Parameters**:
- `upgrade --all`: Update all installed packages
- `--silent`: No user interaction required
- `--accept-source-agreements`: Auto-accept source agreements
- `--accept-package-agreements`: Auto-accept package agreements

### Security Considerations

- ✅ Runs with administrator privileges (required for software installation)
- ✅ No network calls except through winget
- ✅ No telemetry or data collection
- ✅ All operations logged locally
- ✅ Open source - full code transparency
- ✅ Signed MSI installer (when code-signed)

### File Locations

| Item | Path |
|------|------|
| **Executable** | `C:\Program Files\XOGENT\WingetUpdater\XogentWingetUpdater.exe` |
| **Logs** | `%LOCALAPPDATA%\XOGENT\WingetUpdater\logs\` |
| **Scheduled Task** | `\XogentWingetUpdater` |
| **Registry** | `HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\` |

---

## 🤝 Contributing

We welcome contributions! Whether it's bug reports, feature requests, or code improvements.

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/xogent-winget-updater.git
cd xogent-winget-updater

# Install dependencies
dotnet restore

# Build and test
dotnet build
dotnet run --project WingetUpdater/WingetUpdater.csproj
```

### Code Style

- Use standard C# naming conventions
- Follow existing code formatting
- Add XML documentation comments for public methods
- Update README.md for significant changes

### Reporting Issues

When reporting issues, please include:
- Windows version (10 or 11)
- .NET Runtime version
- Winget version
- Error messages or logs
- Steps to reproduce

---

## 📄 License

This project is licensed under the MIT License - see below for details.

```
MIT License

Copyright (c) 2024 XOGENT, INC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Support

### XOGENT Support

For technical support or questions about this software:

- **Main Line**: (678) 208-8866
- **Support Line**: (678) 546-0018
- **Hours**: Monday–Friday, 8AM–5PM EST
- **Emergency**: On-call support available weekends
- **Website**: [www.xogent.com](https://www.xogent.com)
- **Email**: Contact through website

**XOGENT, INC** provides comprehensive security, compliance, and managed IT services with a focus on proactive solutions and measurable results.

### Community Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Documentation**: This README and [NinjaRMM Guide](Deploy/NINJARMM_DEPLOYMENT.md)

---

<div align="center">

**Made with ❤️ by XOGENT, INC**

⭐ Star this repo if you find it useful! ⭐

[Report Bug](../../issues) · [Request Feature](../../issues) · [Documentation](Deploy/NINJARMM_DEPLOYMENT.md)

</div>
