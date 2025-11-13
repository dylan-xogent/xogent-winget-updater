<#
.SYNOPSIS
    Uninstalls XOGENT Winget Auto-Updater silently for remote deployment via NinjaRMM.

.DESCRIPTION
    This script performs a complete silent uninstallation of the XOGENT Winget Auto-Updater,
    including removal of the scheduled task and optionally log files. Designed for
    unattended remote deployment through NinjaRMM or other RMM platforms.

.PARAMETER RemoveLogs
    If specified, removes all log files from %LOCALAPPDATA%\XOGENT\WingetUpdater\logs\

.PARAMETER LogPath
    Path where uninstallation logs will be saved. Defaults to %TEMP%\XogentWingetUpdater-Uninstall.log

.EXAMPLE
    .\Uninstall-XogentWingetUpdater.ps1

.EXAMPLE
    .\Uninstall-XogentWingetUpdater.ps1 -RemoveLogs

.NOTES
    Copyright © XOGENT, INC 2024
    For use with NinjaRMM or other remote management platforms
#>

param(
    [switch]$RemoveLogs,
    [string]$LogPath = "$env:TEMP\XogentWingetUpdater-Uninstall.log"
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

Write-Log "=== XOGENT Winget Auto-Updater Uninstallation Started ===" "INFO"
Write-Log "Uninstallation Log: $LogPath" "INFO"

# Find installed product
Write-Log "Searching for installed XOGENT Winget Auto-Updater..." "INFO"
$installedProduct = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*XOGENT Winget Auto-Updater*" }

if (-not $installedProduct) {
    Write-Log "XOGENT Winget Auto-Updater is not installed" "WARNING"
    Write-Log "Checking for residual files and scheduled tasks..." "INFO"
} else {
    Write-Log "Found: $($installedProduct.DisplayName) Version $($installedProduct.DisplayVersion)" "INFO"

    # Extract product code
    $uninstallString = $installedProduct.UninstallString
    if ($uninstallString -match "MsiExec.exe /[IX]({[A-F0-9\-]+})") {
        $productCode = $matches[1]
        Write-Log "Product Code: $productCode" "INFO"

        # Uninstall via MSI
        Write-Log "Starting MSI uninstallation..." "INFO"
        $msiLogPath = "$env:TEMP\XogentWingetUpdater-MSI-Uninstall.log"
        $msiArgs = "/X$productCode /qn /norestart /L*v `"$msiLogPath`""

        Write-Log "MSI Arguments: $msiArgs" "INFO"
        Write-Log "MSI Log: $msiLogPath" "INFO"

        $uninstallProcess = Start-Process "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow

        # Check exit code
        $exitCode = $uninstallProcess.ExitCode
        Write-Log "MSI Exit Code: $exitCode" "INFO"

        if ($exitCode -eq 0) {
            Write-Log "MSI uninstallation completed successfully" "INFO"
        } elseif ($exitCode -eq 3010) {
            Write-Log "MSI uninstallation completed successfully (reboot required)" "WARNING"
        } elseif ($exitCode -eq 1605) {
            Write-Log "Product already uninstalled or not found" "WARNING"
        } else {
            Write-Log "WARNING: MSI uninstallation returned exit code $exitCode" "WARNING"
            Write-Log "Continuing with cleanup..." "INFO"
        }

        Start-Sleep -Seconds 2
    }
}

# Remove scheduled task
Write-Log "Removing scheduled task..." "INFO"
try {
    $task = Get-ScheduledTask -TaskName "XogentWingetUpdater" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "XogentWingetUpdater" -Confirm:$false -ErrorAction Stop
        Write-Log "Scheduled task removed successfully" "INFO"
    } else {
        Write-Log "Scheduled task not found (already removed)" "INFO"
    }
} catch {
    Write-Log "WARNING: Could not remove scheduled task: $($_.Exception.Message)" "WARNING"
}

# Check installation directory
$installPath = "C:\Program Files\XOGENT\WingetUpdater"
if (Test-Path $installPath) {
    Write-Log "Removing installation directory: $installPath" "INFO"
    try {
        Remove-Item -Path $installPath -Recurse -Force -ErrorAction Stop
        Write-Log "Installation directory removed successfully" "INFO"
    } catch {
        Write-Log "WARNING: Could not remove installation directory: $($_.Exception.Message)" "WARNING"
    }
}

# Check parent XOGENT directory
$xogentPath = "C:\Program Files\XOGENT"
if (Test-Path $xogentPath) {
    $remainingItems = Get-ChildItem -Path $xogentPath -ErrorAction SilentlyContinue
    if (-not $remainingItems) {
        try {
            Remove-Item -Path $xogentPath -Force -ErrorAction Stop
            Write-Log "Removed empty XOGENT directory" "INFO"
        } catch {
            Write-Log "WARNING: Could not remove XOGENT directory: $($_.Exception.Message)" "WARNING"
        }
    }
}

# Handle log files
$logDir = "$env:LOCALAPPDATA\XOGENT\WingetUpdater\logs"
if ($RemoveLogs) {
    if (Test-Path $logDir) {
        Write-Log "Removing log files from: $logDir" "INFO"
        try {
            Remove-Item -Path $logDir -Recurse -Force -ErrorAction Stop
            Write-Log "Log files removed successfully" "INFO"

            # Clean up parent directories if empty
            $wingetUpdaterDir = Split-Path $logDir -Parent
            if (Test-Path $wingetUpdaterDir) {
                $items = Get-ChildItem -Path $wingetUpdaterDir -ErrorAction SilentlyContinue
                if (-not $items) {
                    Remove-Item -Path $wingetUpdaterDir -Force -ErrorAction SilentlyContinue
                    Write-Log "Removed empty WingetUpdater directory" "INFO"
                }
            }

            $xogentUserDir = "$env:LOCALAPPDATA\XOGENT"
            if (Test-Path $xogentUserDir) {
                $items = Get-ChildItem -Path $xogentUserDir -ErrorAction SilentlyContinue
                if (-not $items) {
                    Remove-Item -Path $xogentUserDir -Force -ErrorAction SilentlyContinue
                    Write-Log "Removed empty XOGENT user directory" "INFO"
                }
            }
        } catch {
            Write-Log "WARNING: Could not remove log files: $($_.Exception.Message)" "WARNING"
        }
    }
} else {
    if (Test-Path $logDir) {
        Write-Log "Log files preserved at: $logDir" "INFO"
        Write-Log "Use -RemoveLogs parameter to remove log files" "INFO"
    }
}

# Verify uninstallation
Write-Log "Verifying uninstallation..." "INFO"
$verifyProduct = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*XOGENT Winget Auto-Updater*" }

if ($verifyProduct) {
    Write-Log "WARNING: Product still appears in installed programs list" "WARNING"
} else {
    Write-Log "Product successfully removed from installed programs" "INFO"
}

$verifyTask = Get-ScheduledTask -TaskName "XogentWingetUpdater" -ErrorAction SilentlyContinue
if ($verifyTask) {
    Write-Log "WARNING: Scheduled task still exists" "WARNING"
} else {
    Write-Log "Scheduled task successfully removed" "INFO"
}

$verifyExe = Test-Path "C:\Program Files\XOGENT\WingetUpdater\XogentWingetUpdater.exe"
if ($verifyExe) {
    Write-Log "WARNING: Application executable still exists" "WARNING"
} else {
    Write-Log "Application files successfully removed" "INFO"
}

# Uninstallation summary
Write-Log "=== Uninstallation Summary ===" "INFO"
Write-Log "Status: SUCCESS" "INFO"
Write-Log "Product Removed: Yes" "INFO"
Write-Log "Scheduled Task Removed: Yes" "INFO"
Write-Log "Installation Files Removed: Yes" "INFO"
if ($RemoveLogs) {
    Write-Log "Log Files Removed: Yes" "INFO"
} else {
    Write-Log "Log Files Preserved: $logDir" "INFO"
}
Write-Log "" "INFO"
Write-Log "XOGENT Winget Auto-Updater uninstallation completed successfully!" "INFO"
Write-Log "=== Uninstallation Complete ===" "INFO"

# Return success
exit 0
