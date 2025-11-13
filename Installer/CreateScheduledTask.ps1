# PowerShell script to create scheduled task for Winget Auto-Updater
# This is a backup method if the WiX custom action fails

$taskName = "XogentWingetUpdater"
$exePath = $args[0]  # Passed as argument from installer

if (-not $exePath) {
    Write-Error "Executable path not provided"
    exit 1
}

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create new scheduled task
$action = New-ScheduledTaskAction -Execute $exePath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Automatically updates software via winget on Windows boot"
    Write-Host "Scheduled task created successfully"
    exit 0
} catch {
    Write-Error "Failed to create scheduled task: $_"
    exit 1
}

