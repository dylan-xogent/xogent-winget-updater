<#
.SYNOPSIS
    Installs XOGENT Winget Auto-Updater silently for remote deployment via NinjaRMM.

.DESCRIPTION
    This script performs a silent installation of the XOGENT Winget Auto-Updater,
    including all prerequisites and scheduled task configuration. Designed for
    unattended remote deployment through NinjaRMM or other RMM platforms.

.PARAMETER MsiPath
    Path to the XogentWingetUpdater.msi file. If not specified, uses the same directory as the script.

.PARAMETER LogPath
    Path where installation logs will be saved. Defaults to %TEMP%\XogentWingetUpdater-Install.log

.EXAMPLE
    .\Install-XogentWingetUpdater.ps1

.EXAMPLE
    .\Install-XogentWingetUpdater.ps1 -MsiPath "\\server\share\XogentWingetUpdater.msi"

.NOTES
    Copyright © XOGENT, INC 2024
    For use with NinjaRMM or other remote management platforms
#>

param(
    [string]$MsiPath = "",
    [string]$LogPath = "$env:TEMP\XogentWingetUpdater-Install.log"
)

# Ensure running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Initialize logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logMessage
    Write-Host $logMessage
}

Write-Log "=== XOGENT Winget Auto-Updater Installation Started ===" "INFO"
Write-Log "Installation Log: $LogPath" "INFO"

# Determine MSI path
if ([string]::IsNullOrEmpty($MsiPath)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $MsiPath = Join-Path $scriptDir "XogentWingetUpdater.msi"
}

Write-Log "MSI Path: $MsiPath" "INFO"

# Verify MSI exists
if (-not (Test-Path $MsiPath)) {
    Write-Log "ERROR: MSI installer not found at: $MsiPath" "ERROR"
    exit 1
}

# Check if already installed
Write-Log "Checking for existing installation..." "INFO"
$existingInstall = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*XOGENT Winget Auto-Updater*" }

if ($existingInstall) {
    Write-Log "XOGENT Winget Auto-Updater is already installed (Version: $($existingInstall.DisplayVersion))" "WARNING"
    Write-Log "Uninstalling existing version..." "INFO"

    $uninstallString = $existingInstall.UninstallString
    if ($uninstallString -match "MsiExec.exe /X({[A-F0-9\-]+})") {
        $productCode = $matches[1]
        $uninstallArgs = "/X$productCode /qn /norestart /L*v `"$env:TEMP\XogentWingetUpdater-Uninstall.log`""

        $uninstallProcess = Start-Process "msiexec.exe" -ArgumentList $uninstallArgs -Wait -PassThru -NoNewWindow

        if ($uninstallProcess.ExitCode -eq 0) {
            Write-Log "Previous version uninstalled successfully" "INFO"
        } else {
            Write-Log "Warning: Uninstall returned exit code $($uninstallProcess.ExitCode)" "WARNING"
        }

        Start-Sleep -Seconds 3
    }
}

# Check Windows version
Write-Log "Checking Windows version..." "INFO"
$osVersion = [System.Environment]::OSVersion.Version
Write-Log "Windows Version: $($osVersion.Major).$($osVersion.Minor) Build $($osVersion.Build)" "INFO"

if ($osVersion.Major -lt 10) {
    Write-Log "ERROR: Windows 10 or later is required" "ERROR"
    exit 1
}

# Check for .NET 8.0 Runtime
Write-Log "Checking for .NET 8.0 Runtime..." "INFO"
$dotnetVersion = $null
try {
    $dotnetOutput = & dotnet --list-runtimes 2>&1
    $dotnet8Runtime = $dotnetOutput | Where-Object { $_ -match "Microsoft.WindowsDesktop.App 8\." }

    if ($dotnet8Runtime) {
        Write-Log ".NET 8.0 Runtime found: $dotnet8Runtime" "INFO"
    } else {
        Write-Log "WARNING: .NET 8.0 Runtime not detected. Installation may fail." "WARNING"
        Write-Log ".NET 8.0 Runtime is included in Windows 11 or can be downloaded from:" "WARNING"
        Write-Log "https://dotnet.microsoft.com/download/dotnet/8.0" "WARNING"
    }
} catch {
    Write-Log "WARNING: Could not verify .NET Runtime installation" "WARNING"
}

# Check for Winget
Write-Log "Checking for Winget (App Installer)..." "INFO"
$wingetPath = $null
try {
    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetPath) {
        $wingetVersion = & winget --version
        Write-Log "Winget found: Version $wingetVersion" "INFO"
    } else {
        Write-Log "WARNING: Winget not found. Application will not function without it." "WARNING"
        Write-Log "Install App Installer from Microsoft Store or:" "WARNING"
        Write-Log "https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1" "WARNING"
    }
} catch {
    Write-Log "WARNING: Could not verify Winget installation" "WARNING"
}

# Install the MSI
Write-Log "Starting MSI installation..." "INFO"
$msiLogPath = "$env:TEMP\XogentWingetUpdater-MSI.log"
$msiArgs = "/i `"$MsiPath`" /qn /norestart /L*v `"$msiLogPath`""

Write-Log "MSI Arguments: $msiArgs" "INFO"
Write-Log "MSI Log: $msiLogPath" "INFO"

$installProcess = Start-Process "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow

# Check exit code
$exitCode = $installProcess.ExitCode
Write-Log "MSI Exit Code: $exitCode" "INFO"

if ($exitCode -eq 0) {
    Write-Log "MSI installation completed successfully" "INFO"
} elseif ($exitCode -eq 3010) {
    Write-Log "MSI installation completed successfully (reboot required)" "WARNING"
} else {
    Write-Log "ERROR: MSI installation failed with exit code $exitCode" "ERROR"
    Write-Log "Check MSI log for details: $msiLogPath" "ERROR"
    exit $exitCode
}

# Verify installation
Start-Sleep -Seconds 2
Write-Log "Verifying installation..." "INFO"

$installPath = "C:\Program Files\XOGENT\WingetUpdater\XogentWingetUpdater.exe"
if (Test-Path $installPath) {
    Write-Log "Application installed successfully at: $installPath" "INFO"
} else {
    Write-Log "ERROR: Application executable not found at expected location" "ERROR"
    exit 1
}

# Verify scheduled task
Write-Log "Verifying scheduled task..." "INFO"
try {
    $task = Get-ScheduledTask -TaskName "XogentWingetUpdater" -ErrorAction Stop
    Write-Log "Scheduled task verified: $($task.TaskName)" "INFO"
    Write-Log "Task State: $($task.State)" "INFO"
    Write-Log "Task will run at system startup with highest privileges" "INFO"
} catch {
    Write-Log "WARNING: Scheduled task not found. Attempting to create..." "WARNING"

    try {
        $action = New-ScheduledTaskAction -Execute $installPath
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        Register-ScheduledTask -TaskName "XogentWingetUpdater" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

        Write-Log "Scheduled task created successfully" "INFO"
    } catch {
        Write-Log "ERROR: Failed to create scheduled task: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Create log directory
$logDir = "$env:LOCALAPPDATA\XOGENT\WingetUpdater\logs"
if (-not (Test-Path $logDir)) {
    try {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        Write-Log "Log directory created: $logDir" "INFO"
    } catch {
        Write-Log "WARNING: Could not create log directory: $($_.Exception.Message)" "WARNING"
    }
}

# Installation summary
Write-Log "=== Installation Summary ===" "INFO"
Write-Log "Status: SUCCESS" "INFO"
Write-Log "Installation Path: $installPath" "INFO"
Write-Log "Log Directory: $logDir" "INFO"
Write-Log "Scheduled Task: Configured for system startup" "INFO"
Write-Log "Next Run: At next system boot/reboot" "INFO"
Write-Log "" "INFO"
Write-Log "XOGENT Winget Auto-Updater installation completed successfully!" "INFO"
Write-Log "=== Installation Complete ===" "INFO"

# Return success
exit 0
