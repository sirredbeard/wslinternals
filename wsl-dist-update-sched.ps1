# Define variables
$taskName = "WSL Distro Automatic Update"
$taskDescription = "Runs wsl-dist-update.exe 10 minutes after Windows boots"
$executablePath = "wsl-dist-update.exe"
$arguments = "--system"

# Create scheduled task
$action = New-ScheduledTaskAction -Execute $executablePath -Argument $arguments
$trigger = New-ScheduledTaskTrigger -AtStartup -Delay 10m
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force

# Run scheduled task in the background
Start-ScheduledTask -TaskName $taskName