# Get the total memory and number of cores
$totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$totalCores = (Get-CimInstance Win32_Processor).NumberOfCores

# Determine memory and processor settings based on the selected option
switch ($option) {
    "--standard" {
        $memory = $null
        $processors = $null
    }
    "--minimal" {
        $memory = [math]::Max([math]::Floor($totalMemory * 0.2 / 1GB), 2)
        $processors = [math]::Max([math]::Floor($totalCores * 0.2 / 1GB), 2)
    }
    "--medium" {
        $memory = [math]::Max([math]::Floor($totalMemory * 0.4 / 1GB), 2)
        $processors = [math]::Max([math]::Floor($totalCores * 0.2 / 1GB), 4)
    }
    "--maximal" {
        $memory = [math]::Max([math]::Floor($totalMemory * 0.9 / 1GB), 4)
        $processors = $null
    }
}

# Create or update the .wslconfig file
$configFile = "$env:USERPROFILE\.wslconfig"
if (!(Test-Path $configFile)) {
    New-Item $configFile -ItemType File | Out-Null
}
$config = Get-Content $configFile -Raw
if ($config -match '\[wsl2\]') {
    $config = $config -replace '(?m)^\s*memory\s*=.*', "memory=${memory}GB"
    $config = $config -replace '(?m)^\s*processors\s*=.*', "processors=$processors"
} else {
    $config += "[wsl2]\r\nmemory=${memory}GB\r\nprocessors=$processors\r\n"
}
$config | Set-Content $configFile
