$wtPath = Get-ChildItem "$env:LOCALAPPDATA\Packages\" -Directory | Where-Object { $_.Name -like "Microsoft.WindowsTerminal_*" } | Select-Object -ExpandProperty FullName
$wtpPath = Get-ChildItem "$env:LOCALAPPDATA\Packages\" -Directory | Where-Object { $_.Name -like "Microsoft.WindowsTerminalPreview_*" } | Select-Object -ExpandProperty FullName
$wtcPath = Get-ChildItem "$env:LOCALAPPDATA\Packages\" -Directory | Where-Object { $_.Name -like "Microsoft.WindowsTerminalCanary_*" } | Select-Object -ExpandProperty FullName

if (!$wtPath -and !$wtpPath -and !$wtcPath) {
    Write-Host "Windows Terminal is not installed."
    exit
}

$wslProfile = @{
    name = "WSL System Distro"
    commandline = "wsl.exe -u root --system"
    hidden = $false
    guid = [guid]::NewGuid().ToString("B")
    icon = "C:\Windows\System32\wsl.exe"
    startingDirectory = ""
}

if ($wtPath) {
    Write-Host "Windows Terminal is installed."
    if (Test-Path "$wtPath\LocalState\settings.json") {
        Write-Host "Windows Terminal settings.json found."
    } else {
        Write-Host "Windows Terminal settings.json not found, creating..."
        $wtExePath = Get-ChildItem "$env:ProgramFiles\WindowsApps\Microsoft.WindowsTerminal_1*" -Directory | Select-Object -ExpandProperty FullName
        $mywtProcess = Get-Process -Name "WindowsTerminal"
        $mywtPid = $mywtProcess.Id
        Start-Process "$wtExePath\wt.exe"
        Start-Sleep -Seconds 1
        Get-Process -Name "WindowsTerminal" | Where-Object { $_.Id -ne $mywtPid } | Stop-Process
    }
    $wtSettings = Get-Content "$wtPath\LocalState\settings.json" -Raw | ConvertFrom-Json
    if ($wtSettings.profiles.list | Where-Object { $_.Name -eq $wslProfile.Name }) {
        $wtSettings.profiles.list = $wtSettings.profiles.list | Where-Object { $_.Name -ne $wslProfile.Name }
        }
    $wtSettings.profiles.list += $wslProfile
    $wtSettings | ConvertTo-Json -Depth 100 | Set-Content "$wtPath\LocalState\settings.json"
    Write-Host "Windows Terminal settings.json updated."
}

if ($wtpPath) {
    Write-Host "Windows Terminal Preview is installed."
    if (Test-Path "$wtpPath\LocalState\settings.json") {
        Write-Host "Windows Terminal Preview settings.json found."
    } else {
        Write-Host "Windows Terminal Preview settings.json not found, creating..."
        $wtpExePath = Get-ChildItem "$env:ProgramFiles\WindowsApps\Microsoft.WindowsTerminalPreview_1*" -Directory | Select-Object -ExpandProperty FullName
        $mywtProcess = Get-Process -Name "WindowsTerminal"
        $mywtPid = $mywtProcess.Id
        Start-Process "$wtpExePath\wt.exe"
        Start-Sleep -Seconds 1
        Get-Process -Name "WindowsTerminal" | Where-Object { $_.Id -ne $mywtPid } | Stop-Process
    }
    $wtpSettings = Get-Content "$wtpPath\LocalState\settings.json" -Raw | ConvertFrom-Json
    if ($wtpSettings.profiles.list | Where-Object { $_.Name -eq $wslProfile.Name }) {
        $wtpSettings.profiles.list = $wtpSettings.profiles.list | Where-Object { $_.Name -ne $wslProfile.Name }
    }
    $wtpSettings.profiles.list += $wslProfile
    $wtpSettings | ConvertTo-Json -Depth 100 | Set-Content "$wtpPath\LocalState\settings.json"
    Write-Host "Windows Terminal Preview settings.json updated."
}

if ($wtcPath) {
    Write-Host "Windows Terminal Canary is installed."
    if (Test-Path "$wtpPath\LocalState\settings.json") {
        Write-Host "Windows Terminal Canary settings.json found."
    } else {
        Write-Host "Windows Terminal Canary settings.json not found, creating..."
        $wtpExePath = Get-ChildItem "$env:ProgramFiles\WindowsApps\Microsoft.WindowsTerminalCanary_1*" -Directory | Select-Object -ExpandProperty FullName
        $mywtProcess = Get-Process -Name "WindowsTerminal"
        $mywtPid = $mywtProcess.Id
        Start-Process "$wtpExePath\wt.exe"
        Start-Sleep -Seconds 1
        Get-Process -Name "WindowsTerminal" | Where-Object { $_.Id -ne $mywtPid } | Stop-Process
    }
    $wtpSettings = Get-Content "$wtpPath\LocalState\settings.json" -Raw | ConvertFrom-Json
    if ($wtpSettings.profiles.list | Where-Object { $_.Name -eq $wslProfile.Name }) {
        $wtpSettings.profiles.list = $wtpSettings.profiles.list | Where-Object { $_.Name -ne $wslProfile.Name }
    }
    $wtpSettings.profiles.list += $wslProfile
    $wtpSettings | ConvertTo-Json -Depth 100 | Set-Content "$wtpPath\LocalState\settings.json"
    Write-Host "Windows Terminal Preview settings.json updated."
}