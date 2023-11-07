param (
    [switch]$reset,
    [switch]$hardReset,
    [switch]$destructiveReset
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an administrator."
    Exit 1
}

switch ($true) {
    $reset {
        wsl.exe --shutdown -ErrorAction SilentlyContinue 2>$null
        Restart-Service "Windows Subsystem for Linux" -Force -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -ne 0) {
            Restart-Service LxssManager -Force -ErrorAction SilentlyContinue
        }
        wsl.exe --update > $null
        Write-Host "WSL has been shutdown, Windows service restarted, and updated, if applicable."
    }
    $hardReset {
        wsl.exe --shutdown -ErrorAction SilentlyContinue 2>$null
        Stop-Service "Windows Subsystem for Linux" -Force -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -ne 0) {
            Stop-Service LxssManager -Force -ErrorAction SilentlyContinue
        }
        if (-not (Get-AppxPackage *WindowsSubsystemForLinux* | Remove-AppxPackage -ErrorAction SilentlyContinue 2>$null)) {
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue 2>$null
        }
        wsl.exe --install --no-launch --no-distribution
        Write-Host "WSL has been shutdown and re-installed."
    }
    $destructiveReset {
        wsl.exe --shutdown -ErrorAction SilentlyContinue 2>$null
        Restart-Service "Windows Subsystem for Linux" -Force -ErrorAction SilentlyContinue
        if ($LASTEXITCODE -ne 0) {
            Restart-Service LxssManager -Force -ErrorAction SilentlyContinue
        }
        $distros = Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object { $_.GetValue("DistributionName") }
        foreach ($distro in $distros) {
            wsl.exe --unregister $distro -ErrorAction SilentlyContinue 2>$null
            $folder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\$distro"
            if (Test-Path $folder) {
                Remove-Item $folder -Recurse -Force
            }
        }
        if (-not (Get-AppxPackage *WindowsSubsystemForLinux* | Remove-AppxPackage -ErrorAction SilentlyContinue 2>$null)) {
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue 2>$null
        }
        wsl.exe --install --no-launch --no-distribution
        Write-Host "WSL has been shutdown, all distros unregistered, and WSL has been re-installed."
    }
    default {
        Write-Error "This script must be run with either -reset, -hardreset, or -destructivereset."
        Exit 1
    }
}