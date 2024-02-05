# Check for winget update parameter
param(
    [switch]$winget,
    [switch]$scoop,
    [switch]$wsl,
    [switch]$wslpr
)

# Get list of installed WSL distros from registry
$distros = Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" | ForEach-Object { $_.GetValue("DistributionName") }

# Loop through each distro and get ID_LIKE variable from /etc/os-release using wsl.exe
$results = foreach ($distro in $distros) {
    if ($distro -eq "docker-desktop" -or $distro -eq "docker-desktop-data" -or $distro -eq "podman-machine-default" -or $distro -eq "rancher-desktop" -or $distro -eq "rancher-desktop-data") {
        continue
    }
    $osReleasePath = "\\wsl$\$distro\etc\os-release"
    #$idLike = (wsl.exe -d $distro cat /etc/os-release | Select-String "^ID_LIKE=").ToString().Split("=")[1]
    $id = (wsl.exe -d $distro cat /etc/os-release | Select-String "^ID=").ToString().Split("=")[1]
    Write-Host "Updating $(if ($distro -eq 'WLinux') { 'Pengwin' } elseif ($distro -eq 'fedoraremix') { 'Fedora Remix for WSL' } else { $distro })"
    switch -Wildcard ($id) {
        "*debian*" {
            wsl.exe -d $distro -u root -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get update -y > /dev/null"
            wsl.exe -d $distro -u root -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y > /dev/null"
        }
        "*ubuntu*" {
            wsl.exe -d $distro -u root -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get update -y > /dev/null"
            wsl.exe -d $distro -u root -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y > /dev/null"
        }
        "*fedora*" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }
        "*rhel*" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }
        "almalinux" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }
        "rocky" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }
        "scientific" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }
        "centos" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }         
        "*alpine*" {
            wsl.exe -d $distro -u root apk update > $null
            wsl.exe -d $distro -u root apk upgrade -y > $null
        }
        "*suse*" {
            wsl.exe -d $distro -u root zypper dup -y > $null
        }
        "*sles*" {
            wsl.exe -d $distro -u root zypper dup -y > $null
        }
        "*arch*" {
            wsl.exe -d $distro -u root pacman -Sy archlinux-keyring --noconfirm > $null
            wsl.exe -d $distro -u root pacman-key --init > $null
            wsl.exe -d $distro -u root pacman -Syu --noconfirm > $null
        }
        "openEuler" {
            Write-Host wsl.exe -d $distro -u root dnf update -y
            wsl.exe -d $distro -u root dnf update -y > $null
        }
    }
    [PSCustomObject]@{
        DistroName = $distro
        ID_LIKE = $idLike
    }
}

# Update winget
if ($PSBoundParameters.ContainsKey('winget')) {
    $wingetCommand = Get-Command winget -ErrorAction SilentlyContinue

    if ($wingetCommand) {
        Write-Host "Updating winget"
        winget update --all --include-unknown > $null
    }
}

# Update scoop
if ($PSBoundParameters.ContainsKey('scoop')) {
    $scoopCommand = Get-Command scoop update -ErrorAction SilentlyContinue

    if ($scoopCommand) {
        Write-Host "Updating scoop"
        powershell -NonInteractive -NoProfile -Command "scoop update *" > $null 2>&1
    }
}

# Update WSL
if ($PSBoundParameters.ContainsKey('wsl')) {
    $wslCommand = Get-Command "wsl" -ErrorAction SilentlyContinue

    if ($wslCommand) {
        Write-Host "Updating WSL"
        powershell -NonInteractive -NoProfile -Command "wsl.exe --update" > $null 2>&1
    }
}

# Update WSL Pre-Release
if ($PSBoundParameters.ContainsKey('wslpr')) {
    $wslprCommand = Get-Command "wsl" -ErrorAction SilentlyContinue

    if ($wslprCommand) {
        Write-Host "Updating WSL Pre-Release"
        powershell -NonInteractive -NoProfile -Command "wsl.exe --update --pre-release" > $null 2>&1
    }
}