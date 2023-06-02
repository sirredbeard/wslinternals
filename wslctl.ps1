# Check if the script is being run as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an administrator."
    Exit 1
}

# Parse command line arguments
$operation = $args[0]
$distroName = $args[1]

# Check if a WSL distro name was specified
if (-not $distroName) {
    Write-Error "A WSL distro name must be specified."
    Exit 1
}

# If the distro name is Pengwin, use WLinux instead
if ($distroName -eq "Pengwin") {
    $distroName = "WLinux"
}

# Check if the specified WSL distro exists
$distroGuids = Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" | Select-Object -ExpandProperty PSChildName
$distroGuid = $distroGuids | ForEach-Object {
    if ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss\$_").DistributionName -eq $distroName) {
        return $_
    }
}
if (-not $distroGuid) {
    Write-Error "The specified WSL distro does not exist."
    Exit 1
}

# Check if the specified WSL distro is enabled
$taskName = "Start $distroName at startup"
$taskPath = "\Microsoft\Windows\WSL"
$taskExists = Get-ScheduledTask -TaskName $taskName -CimSession (New-CimSession -SessionOption (New-CimSessionOption -Protocol Dcom)) -ErrorAction SilentlyContinue
if ($operation -eq "enable") {
    if ($taskExists) {
        Write-Error "The specified WSL distro has already been enabled."
        Exit 1
    }
    $taskAction = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "-d $distroGuid"
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8
    $task = New-ScheduledTask -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -ErrorAction SilentlyContinue
    $task | Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    Write-Host "The specified WSL distro has been enabled."
} elseif ($operation -eq "disable") {
    if (-not $taskExists) {
        Write-Error "The specified WSL distro is not enabled."
        Exit 1
    }
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "The specified WSL distro has been disabled."
} elseif ($operation -eq "restart") {
    if (-not $taskExists) {
        Write-Error "The specified WSL distro is not enabled."
        Exit 1
    }
    Disable-ScheduledTask -TaskName $taskName -TaskPath $taskPath -CimSession (New-CimSession -SessionOption (New-CimSessionOption -Protocol Dcom))
    Enable-ScheduledTask -TaskName $taskName -TaskPath $taskPath -CimSession (New-CimSession -SessionOption (New-CimSessionOption -Protocol Dcom))
    wsl.exe -d $distroName -u root -- shutdown -r now
}
