# Get list of installed WSL distros from registry
$distros = Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" | ForEach-Object { $_.GetValue("DistributionName") }

# Loop through each distro and get ID_LIKE variable from /etc/os-release using wsl.exe
$results = foreach ($distro in $distros) {
    $osReleasePath = "\\wsl$\$distro\etc\os-release"
    #$idLike = (wsl.exe -d $distro cat /etc/os-release | Select-String "^ID_LIKE=").ToString().Split("=")[1]
    $id = (wsl.exe -d $distro cat /etc/os-release | Select-String "^ID=").ToString().Split("=")[1]
    Write-Host "Updating $distro"
    switch -Wildcard ($id) {
        "*debian*" {
            wsl.exe -d $distro -u root apt-get update > $null
            wsl.exe -d $distro -u root apt-get upgrade -y > $null
        }
        "*ubuntu*" {
            wsl.exe -d $distro -u root apt-get update > $null
            wsl.exe -d $distro -u root apt-get upgrade -y > $null
        }
        "*fedora*" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }
        "*rhel*" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }
        "*alpine*" {
            wsl.exe -d $distro -u root apk update > $null
            wsl.exe -d $distro -u root apk upgrade -y > $null
        }
        "almalinux" {
            wsl.exe -d $distro -u root dnf update -y > $null
        }
        "*suse*" {
            wsl.exe -d $distro -u root zypper dup -y > $null
        }
        "*arch*" {
            wsl.exe -d $distro -u root pacman -Syu --noconfirm > $null
        }
    }
    [PSCustomObject]@{
        DistroName = $distro
        ID_LIKE = $idLike
    }
}