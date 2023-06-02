$skipUsername = $false
if ($args -contains "--skip-username") {
    $skipUsername = $true
}

$wslRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
$wslRegKeys = Get-ChildItem $wslRegPath

$table = @()
foreach ($key in $wslRegKeys) {
    $distroName = (Get-ItemProperty -Path $key.PSPath -Name DistributionName).DistributionName
    $defaultUid = (Get-ItemProperty -Path $key.PSPath -Name DefaultUid).DefaultUid
    $state = (Get-ItemProperty -Path $key.PSPath -Name State).State
    $version = (Get-ItemProperty -Path $key.PSPath -Name Version).Version

    if ($skipUsername) {
        $table += [pscustomobject]@{
            "Distribution Name" = $distroName
            "Default UID" = $defaultUid
            "State" = switch ($state) {
                0x1 { "Installed" }
                0x3 { "Installing" }
                0x4 { "Uninstalling" }
            }
            "Version" = $version
        }
    } else {
        $defaultUser = Invoke-Command -ScriptBlock { wsl.exe -d $args[0] -- id -un -- $args[1] } -ArgumentList $distroName, $defaultUid -ErrorAction SilentlyContinue
        $table += [pscustomobject]@{
            "Distribution Name" = $distroName
            "Default UID" = $defaultUid
            "Default User" = $defaultUser
            "State" = switch ($state) {
                0x1 { "Installed" }
                0x3 { "Installing" }
                0x4 { "Uninstalling" }
            }
            "Version" = $version
        }
    }
}

$table | Format-Table -AutoSize
