<#
.SYNOPSIS
    Verifies XOGENT Winget Auto-Updater installation and health status.

.DESCRIPTION
    This script checks the installation status, scheduled task configuration,
    prerequisites, and recent execution logs. Designed for monitoring and
    troubleshooting through NinjaRMM or other RMM platforms.

.PARAMETER Detailed
    If specified, provides detailed output including log file analysis

.PARAMETER ExitOnError
    If specified, exits with non-zero code if any issues are detected

.EXAMPLE
    .\Verify-XogentWingetUpdater.ps1

.EXAMPLE
    .\Verify-XogentWingetUpdater.ps1 -Detailed -ExitOnError

.NOTES
    Copyright © XOGENT, INC 2024
    For use with NinjaRMM or other remote management platforms

    Exit Codes:
    0 - All checks passed
    1 - Installation not found
    2 - Scheduled task issues
    3 - Missing prerequisites
    4 - Recent execution failures
#>

param(
    [switch]$Detailed,
    [switch]$ExitOnError
)

$ErrorActionPreference = "Continue"
$issues = @()
$warnings = @()

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        default { "White" }
    }
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

Write-Host ""
Write-Host "=== XOGENT Winget Auto-Updater Verification ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

# Check 1: Installation Status
Write-Host "Checking Installation Status..." -ForegroundColor Yellow
$installed = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*XOGENT Winget Auto-Updater*" }

if ($installed) {
    Write-Status "Product is installed: $($installed.DisplayName)" "PASS"
    Write-Status "Version: $($installed.DisplayVersion)" "INFO"
    Write-Status "Install Date: $($installed.InstallDate)" "INFO"
} else {
    Write-Status "Product is NOT installed" "FAIL"
    $issues += "Product not found in installed programs"
}

# Check 2: Application Executable
Write-Host ""
Write-Host "Checking Application Files..." -ForegroundColor Yellow
$exePath = "C:\Program Files\XOGENT\WingetUpdater\XogentWingetUpdater.exe"

if (Test-Path $exePath) {
    $fileInfo = Get-Item $exePath
    Write-Status "Executable found: $exePath" "PASS"
    Write-Status "File Size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" "INFO"
    Write-Status "Last Modified: $($fileInfo.LastWriteTime)" "INFO"
    Write-Status "Version: $($fileInfo.VersionInfo.FileVersion)" "INFO"
} else {
    Write-Status "Executable NOT found at: $exePath" "FAIL"
    $issues += "Application executable missing"
}

# Check 3: Scheduled Task
Write-Host ""
Write-Host "Checking Scheduled Task..." -ForegroundColor Yellow
try {
    $task = Get-ScheduledTask -TaskName "XogentWingetUpdater" -ErrorAction Stop
    Write-Status "Scheduled task found: $($task.TaskName)" "PASS"
    Write-Status "State: $($task.State)" "INFO"

    $taskInfo = Get-ScheduledTaskInfo -TaskName "XogentWingetUpdater" -ErrorAction SilentlyContinue
    if ($taskInfo) {
        Write-Status "Last Run Time: $($taskInfo.LastRunTime)" "INFO"
        Write-Status "Last Result: $($taskInfo.LastTaskResult)" "INFO"
        Write-Status "Next Run Time: $($taskInfo.NextRunTime)" "INFO"

        if ($taskInfo.LastTaskResult -ne 0 -and $taskInfo.LastRunTime -gt (Get-Date).AddDays(-7)) {
            Write-Status "Recent execution failed with code: $($taskInfo.LastTaskResult)" "WARN"
            $warnings += "Last task execution failed"
        }
    }

    # Check task configuration
    $trigger = $task.Triggers | Where-Object { $_.CimClass.CimClassName -eq "MSFT_TaskBootTrigger" }
    if ($trigger) {
        Write-Status "Trigger: At system startup (configured correctly)" "PASS"
    } else {
        Write-Status "Trigger: Not configured for startup" "WARN"
        $warnings += "Task trigger not set for startup"
    }

    if ($task.Principal.RunLevel -eq "Highest") {
        Write-Status "Privileges: Highest (configured correctly)" "PASS"
    } else {
        Write-Status "Privileges: $($task.Principal.RunLevel)" "WARN"
        $warnings += "Task not running with highest privileges"
    }

} catch {
    Write-Status "Scheduled task NOT found" "FAIL"
    $issues += "Scheduled task missing"
}

# Check 4: Prerequisites
Write-Host ""
Write-Host "Checking Prerequisites..." -ForegroundColor Yellow

# .NET Runtime
try {
    $dotnetRuntimes = & dotnet --list-runtimes 2>&1 | Where-Object { $_ -match "Microsoft.WindowsDesktop.App 8\." }
    if ($dotnetRuntimes) {
        Write-Status ".NET 8.0 Runtime: Installed" "PASS"
        if ($Detailed) {
            $dotnetRuntimes | ForEach-Object { Write-Status "  $_" "INFO" }
        }
    } else {
        Write-Status ".NET 8.0 Runtime: NOT found" "WARN"
        $warnings += ".NET 8.0 Runtime not detected"
    }
} catch {
    Write-Status ".NET Runtime: Unable to verify" "WARN"
}

# Winget
try {
    $wingetVersion = & winget --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Winget: Installed (Version $wingetVersion)" "PASS"
    } else {
        Write-Status "Winget: NOT found or not working" "WARN"
        $warnings += "Winget not available"
    }
} catch {
    Write-Status "Winget: NOT found" "WARN"
    $warnings += "Winget not available"
}

# Check 5: Log Directory and Recent Logs
Write-Host ""
Write-Host "Checking Logs..." -ForegroundColor Yellow
$logDir = "$env:LOCALAPPDATA\XOGENT\WingetUpdater\logs"

if (Test-Path $logDir) {
    Write-Status "Log directory exists: $logDir" "PASS"

    $logFiles = Get-ChildItem -Path $logDir -Filter "updater-*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending

    if ($logFiles) {
        Write-Status "Total log files: $($logFiles.Count)" "INFO"

        $recentLog = $logFiles | Select-Object -First 1
        Write-Status "Most recent log: $($recentLog.Name)" "INFO"
        Write-Status "Last execution: $($recentLog.LastWriteTime)" "INFO"

        if ($Detailed) {
            Write-Host ""
            Write-Host "Recent Log Summary:" -ForegroundColor Yellow
            $logContent = Get-Content $recentLog.FullName -Tail 20
            $logContent | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }

        # Check for recent execution
        $sevenDaysAgo = (Get-Date).AddDays(-7)
        if ($recentLog.LastWriteTime -lt $sevenDaysAgo) {
            Write-Status "WARNING: No execution in the last 7 days" "WARN"
            $warnings += "No recent execution detected"
        }
    } else {
        Write-Status "No log files found" "WARN"
        $warnings += "No execution logs found"
    }
} else {
    Write-Status "Log directory does not exist" "WARN"
    $warnings += "Log directory not created (application may not have run yet)"
}

# Check 6: System Information
if ($Detailed) {
    Write-Host ""
    Write-Host "System Information..." -ForegroundColor Yellow
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Status "OS: $($os.Caption)" "INFO"
    Write-Status "Version: $($os.Version)" "INFO"
    Write-Status "Build: $($os.BuildNumber)" "INFO"
    Write-Status "Last Boot: $($os.LastBootUpTime)" "INFO"

    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-Status "Uptime: $($uptime.Days) days, $($uptime.Hours) hours" "INFO"
}

# Summary
Write-Host ""
Write-Host "=== Verification Summary ===" -ForegroundColor Cyan

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "Status: " -NoNewline
    Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "XOGENT Winget Auto-Updater is properly installed and configured." -ForegroundColor Green
    exit 0
} else {
    if ($issues.Count -gt 0) {
        Write-Host ""
        Write-Host "CRITICAL ISSUES FOUND:" -ForegroundColor Red
        $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }

    if ($warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "WARNINGS:" -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }

    Write-Host ""
    if ($ExitOnError) {
        if ($issues.Count -gt 0) {
            Write-Host "Exiting with error code" -ForegroundColor Red
            if ($issues -match "Product not found") { exit 1 }
            if ($issues -match "Scheduled task") { exit 2 }
            if ($issues -match "executable") { exit 1 }
            exit 1
        } elseif ($warnings.Count -gt 0) {
            if ($warnings -match "Winget") { exit 3 }
            if ($warnings -match "execution") { exit 4 }
            exit 4
        }
    }
}

exit 0
