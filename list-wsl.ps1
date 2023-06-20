$defaultGuid = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss").DefaultDistribution

$wslDistributions = Get-ChildItem -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" | ForEach-Object {
    $distribution = @{}
    $distribution["Name"] = $_.GetValue("DistributionName")
    $distribution["State"] = "Installed"
    $distribution["WSL"] = 2
    $distribution["systemd"] = "Disabled"
    $distribution["Default User"] = ""
    $distribution["Distro Version"] = ""
    $distribution["Linux Distro"] = ""

    if ($distribution["Name"] -eq "docker-desktop") {
        $distribution["Linux Distro"] = "Docker Desktop"
    } elseif ($distribution["Name"] -eq "docker-desktop-data") {
        $distribution["Linux Distro"] = "Docker Desktop Data"
    } elseif ($distribution["Name"] -eq "docker-desktop-runtime") {
        $distribution["Linux Distro"] = "Docker Desktop Runtime"
    } elseif ($distribution["Name"] -eq "rancher-desktop") {
        $distribution["Linux Distro"] = "Rancher Desktop WSL Distribution"
    } elseif ($distribution["Name"] -eq "rancher-desktop-data") {
        $distribution["Linux Distro"] = "Rancher Desktop Data"
    } else {
        $distribution["State"] = ""
    }

    if ($distribution["Name"] -ne "docker-desktop" -and $distribution["Name"] -ne "docker-desktop-data" -and $distribution["Name"] -ne "docker-desktop-runtime" -and $distribution["Name"] -ne "rancher-desktop" -and $distribution["Name"] -ne "rancher-desktop-data") {
        $osRelease = Invoke-Expression "wsl.exe -d $($distribution["Name"]) cat /etc/os-release"
        if ($osRelease) {
            $distribution["Linux Distro"] = ($osRelease | Where-Object { $_ -like "PRETTY_NAME=*" }).Split("=")[1].Replace('"', '')
            $distribution["Distro Version"] = ($osRelease | Where-Object { $_ -like "*VERSION=*" }).Split("=")[1].Replace('"', '')
        }

        $wslConf = Invoke-Expression "wsl.exe -d $($distribution["Name"]) cat /etc/wsl.conf 2> `$null"
        if ($wslConf -and $wslConf.Contains("systemd=true")) {
            $distribution["systemd"] = "Enabled"
        } else {
            $distribution["systemd"] = "Disabled"
        }

        $distribution["DefaultUid"] = $_.GetValue("DefaultUid")

        $username = Invoke-Command -ScriptBlock { wsl.exe -d $($distribution["Name"]) -- id -un -- $args[0] } -ArgumentList $distribution["DefaultUid"] -ErrorAction SilentlyContinue
        if ($username) {
            $distribution["Default User"] = $username
        }

        $distribution["State"] = $_.GetValue("State")
        switch ($distribution["State"]) {
            0x1 { $distribution["State"] = "Installed" }
            0x3 { $distribution["State"] = "Installing" }
            0x4 { $distribution["State"] = "Uninstalling" }
        }

        $distribution["WSL"] = $_.GetValue("Version")

        if ($defaultGuid -eq $_.PSChildName) {
            $distribution["Name"] += "*"
        }
    }

    New-Object -TypeName PSObject -Property $distribution
}

$wslDistributions | Format-Table -AutoSize "Name", "Linux Distro", "Distro Version", "Default User", systemd, State, WSL