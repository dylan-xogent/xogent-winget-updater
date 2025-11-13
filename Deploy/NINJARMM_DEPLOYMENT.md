# NinjaRMM Deployment Guide
## XOGENT Winget Auto-Updater

**Copyright © XOGENT, INC 2024**

This guide provides step-by-step instructions for deploying the XOGENT Winget Auto-Updater across client devices using NinjaRMM.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Deployment Scripts](#deployment-scripts)
3. [NinjaRMM Setup](#ninjarmm-setup)
4. [Deployment Methods](#deployment-methods)
5. [Monitoring & Verification](#monitoring--verification)
6. [Troubleshooting](#troubleshooting)
7. [Uninstallation](#uninstallation)

---

## Prerequisites

### System Requirements
- **Operating System**: Windows 10/11
- **.NET Runtime**: .NET 8.0 Desktop Runtime (included in Windows 11)
- **Winget**: App Installer from Microsoft Store
- **Permissions**: Administrator/SYSTEM account access

### Files Required
- `XogentWingetUpdater.msi` - MSI installer package
- `Install-XogentWingetUpdater.ps1` - Installation script
- `Uninstall-XogentWingetUpdater.ps1` - Uninstallation script
- `Verify-XogentWingetUpdater.ps1` - Verification script

---

## Deployment Scripts

### 1. Install-XogentWingetUpdater.ps1

**Purpose**: Silent installation with prerequisite checking and logging.

**Features**:
- ✅ Automatic prerequisite detection (.NET, Winget)
- ✅ Existing version detection and upgrade
- ✅ Scheduled task verification/creation
- ✅ Comprehensive logging
- ✅ Zero user interaction required

**Usage**:
```powershell
# Basic installation (MSI in same directory)
.\Install-XogentWingetUpdater.ps1

# Specify MSI path
.\Install-XogentWingetUpdater.ps1 -MsiPath "\\server\share\XogentWingetUpdater.msi"

# Custom log location
.\Install-XogentWingetUpdater.ps1 -LogPath "C:\Logs\install.log"
```

**Exit Codes**:
- `0` - Success
- `1` - Error (check log file)
- `3010` - Success (reboot required)

---

### 2. Uninstall-XogentWingetUpdater.ps1

**Purpose**: Complete removal of application and components.

**Features**:
- ✅ MSI uninstallation
- ✅ Scheduled task removal
- ✅ File cleanup
- ✅ Optional log file removal
- ✅ Comprehensive logging

**Usage**:
```powershell
# Basic uninstallation (preserves logs)
.\Uninstall-XogentWingetUpdater.ps1

# Remove logs as well
.\Uninstall-XogentWingetUpdater.ps1 -RemoveLogs

# Custom log location
.\Uninstall-XogentWingetUpdater.ps1 -LogPath "C:\Logs\uninstall.log"
```

**Exit Codes**:
- `0` - Success
- `1` - Error (check log file)

---

### 3. Verify-XogentWingetUpdater.ps1

**Purpose**: Health check and monitoring.

**Features**:
- ✅ Installation verification
- ✅ Scheduled task status
- ✅ Prerequisite checking
- ✅ Recent execution analysis
- ✅ Detailed reporting

**Usage**:
```powershell
# Basic verification
.\Verify-XogentWingetUpdater.ps1

# Detailed output with log analysis
.\Verify-XogentWingetUpdater.ps1 -Detailed

# Exit with error code if issues found
.\Verify-XogentWingetUpdater.ps1 -ExitOnError
```

**Exit Codes**:
- `0` - All checks passed
- `1` - Installation not found
- `2` - Scheduled task issues
- `3` - Missing prerequisites
- `4` - Recent execution failures

---

## NinjaRMM Setup

### Method 1: Software Deployment (Recommended)

#### Step 1: Upload MSI Package

1. Navigate to **Administration** → **Software**
2. Click **Add Software**
3. **Upload** `XogentWingetUpdater.msi`
4. Fill in details:
   - **Name**: XOGENT Winget Auto-Updater
   - **Version**: 1.0.0
   - **Category**: Maintenance Tools
   - **Manufacturer**: XOGENT, INC

#### Step 2: Configure Installation Command

**Install Command**:
```cmd
msiexec /i XogentWingetUpdater.msi /qn /norestart /L*v "%TEMP%\XogentInstall.log"
```

**Uninstall Command**:
```cmd
msiexec /x {PRODUCT-GUID} /qn /norestart /L*v "%TEMP%\XogentUninstall.log"
```
*Note: Replace {PRODUCT-GUID} with actual GUID from MSI*

#### Step 3: Deploy to Devices

1. Go to **Devices** or **Organizations**
2. Select target device(s)/organization(s)
3. Click **Actions** → **Install Software**
4. Select **XOGENT Winget Auto-Updater**
5. Choose deployment schedule:
   - **Immediate**: Deploys right away
   - **Scheduled**: Deploy at specific time
   - **At Next Checkin**: Deploy when device checks in

---

### Method 2: Script Deployment (Advanced)

#### Step 1: Create Installation Script

1. Navigate to **Administration** → **Scripting**
2. Click **New Script**
3. Configure:
   - **Name**: Install XOGENT Winget Auto-Updater
   - **Category**: Deployment
   - **Script Type**: PowerShell

#### Step 2: Script Content

```powershell
#Requires -RunAsAdministrator

# Download MSI from your file server or Azure Blob Storage
$msiUrl = "https://your-storage.blob.core.windows.net/software/XogentWingetUpdater.msi"
$msiPath = "$env:TEMP\XogentWingetUpdater.msi"
$logPath = "$env:TEMP\XogentInstall.log"

try {
    # Download MSI
    Write-Host "Downloading XOGENT Winget Auto-Updater..."
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing

    # Install
    Write-Host "Installing..."
    $process = Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart /L*v `"$logPath`"" -Wait -PassThru

    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        Write-Host "Installation successful!"
        exit 0
    } else {
        Write-Host "Installation failed with exit code: $($process.ExitCode)"
        exit 1
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
} finally {
    # Cleanup
    if (Test-Path $msiPath) {
        Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
    }
}
```

#### Step 3: Deploy Script

1. Select target device(s)
2. Click **Actions** → **Run Script**
3. Select **Install XOGENT Winget Auto-Updater**
4. Click **Run**

---

### Method 3: PowerShell Script with File Transfer

1. **Upload** `Install-XogentWingetUpdater.ps1` and `XogentWingetUpdater.msi` to NinjaRMM file storage
2. Create script that:
   - Downloads both files
   - Runs installation script
   - Reports results

**Example**:
```powershell
$scriptUrl = "https://your-storage/Install-XogentWingetUpdater.ps1"
$msiUrl = "https://your-storage/XogentWingetUpdater.msi"

$tempDir = "$env:TEMP\XogentDeploy"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Invoke-WebRequest -Uri $scriptUrl -OutFile "$tempDir\Install.ps1"
Invoke-WebRequest -Uri $msiUrl -OutFile "$tempDir\XogentWingetUpdater.msi"

Set-Location $tempDir
.\Install.ps1

Remove-Item $tempDir -Recurse -Force
```

---

## Monitoring & Verification

### Create Monitoring Script

1. Navigate to **Administration** → **Scripting**
2. Create new script: **Verify XOGENT Winget Auto-Updater**
3. Use the `Verify-XogentWingetUpdater.ps1` content
4. Schedule to run:
   - **Daily** or **Weekly**
   - Set alert conditions on exit code

### Custom Field Creation (Optional)

Create custom fields to track:
- Installation status
- Last execution time
- Version installed

**Custom Field Script**:
```powershell
$installed = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName -like "*XOGENT Winget*" }

if ($installed) {
    Ninja-Property-Set xogentWingetVersion $installed.DisplayVersion
    Ninja-Property-Set xogentWingetStatus "Installed"
} else {
    Ninja-Property-Set xogentWingetStatus "Not Installed"
}
```

---

## Troubleshooting

### Common Issues

#### Issue 1: .NET 8.0 Runtime Not Found

**Solution**: Pre-install .NET 8.0 Runtime
```powershell
# Download and install .NET 8.0 Desktop Runtime
$dotnetUrl = "https://download.visualstudio.microsoft.com/download/pr/..."
Invoke-WebRequest -Uri $dotnetUrl -OutFile "$env:TEMP\dotnet-runtime.exe"
Start-Process "$env:TEMP\dotnet-runtime.exe" -ArgumentList "/install /quiet /norestart" -Wait
```

#### Issue 2: Winget Not Available

**Solution**: Install App Installer
```powershell
# Install from Microsoft Store (requires Store access)
# Or download directly:
Add-AppxPackage -Path "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
```

#### Issue 3: Scheduled Task Not Running

**Check**:
```powershell
Get-ScheduledTask -TaskName "XogentWingetUpdater" | Get-ScheduledTaskInfo
```

**Recreate**:
```powershell
$action = New-ScheduledTaskAction -Execute "C:\Program Files\XOGENT\WingetUpdater\XogentWingetUpdater.exe"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "XogentWingetUpdater" -Action $action -Trigger $trigger -Principal $principal -Force
```

### Log Locations

- **Installation Log**: `%TEMP%\XogentWingetUpdater-Install.log`
- **MSI Log**: `%TEMP%\XogentWingetUpdater-MSI.log`
- **Application Logs**: `%LOCALAPPDATA%\XOGENT\WingetUpdater\logs\`

---

## Uninstallation

### Option 1: NinjaRMM Software Management

1. Navigate to device
2. **Installed Software** → Find **XOGENT Winget Auto-Updater**
3. Click **Uninstall**

### Option 2: Uninstall Script

1. Deploy `Uninstall-XogentWingetUpdater.ps1`
2. Run via NinjaRMM script execution

### Option 3: Manual Command

```powershell
msiexec /x {PRODUCT-GUID} /qn /norestart
```

---

## Best Practices

1. **Test Deployment**: Deploy to test group first
2. **Schedule Wisely**: Deploy during maintenance windows
3. **Monitor Logs**: Check execution logs regularly
4. **Update Regularly**: Keep MSI package current
5. **Document Changes**: Track deployments in NinjaRMM

---

## Support

For technical support or questions:
- **Phone**: (678) 208-8866
- **Support Line**: (678) 546-0018
- **Hours**: Monday–Friday, 8AM–5PM EST
- **Website**: [www.xogent.com](https://www.xogent.com)

---

**XOGENT, INC** - Security, Compliance, and Managed IT Services
