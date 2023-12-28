# Define optional parameters
param(
    [switch]$force,
    [string]$customConfig,
    [switch]$skipClean,
    [switch]$revert
)

# Function to convert a Windows path to a WSL path
function Convert-PathToWSL($path) {
    return "/mnt/" + ($path -replace ":", "").Replace("\", "/").ToLower()
}

# Revert to the default kernel if -revert is used
if ($revert) {
    Write-Host "Reverting to the default kernel" -ForegroundColor Green
    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    if (Test-Path -Path $wslConfigPath) {
        $wslConfig = Get-Content -Path $wslConfigPath
        $kernelLineIndex = $wslConfig | Select-String -Pattern 'kernel=' | Select-Object LineNumber
        if ($kernelLineIndex) {
            $wslConfig[$kernelLineIndex.LineNumber - 1] = "#kernel="
        }
        $wslConfig | Out-File -FilePath $wslConfigPath -Encoding ascii
    }
    Exit 0
}

# Check if a custom kernel is already set and exit if -force is not used
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
if ((Test-Path -Path $wslConfigPath) -and (Select-String -Path $wslConfigPath -Pattern 'kernel=' -Quiet) -and !$force) {
    Write-Error "A custom kernel is set in $wslConfigPath. Use -force to override." 
    Exit 1
}

# Check if a custom kernel config is set and if it exists
if ($customConfig -and !(Test-Path -Path $customConfig)) {
    Write-Error "The custom kernel config file $customConfig does not exist."
    Exit 1
} elseif ($customConfig) {
    Write-Host "Using kernel custom config $customConfig" -ForegroundColor Green
}

# Install kernel build dependencies in the WSL system distro
Write-Host "Installing kernel build dependencies in the WSL system distro" -ForegroundColor Green
wsl --system --user root tdnf install -y gcc glibc-devel kernel-headers make gawk tar bc perl python3 bison flex dwarves binutils diffutils elfutils-libelf-devel zlib-devel openssl-devel

# Detect the latest release of WSL2-Linux-Kernel on GitHub
Write-Host "Detecting the latest release of WSL2-Linux-Kernel on GitHub" -ForegroundColor Green
$latestRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest'

# Form the kernel tar URL
$downloadUrl = "https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/$($latestRelease.tag_name).tar.gz"

# Download the latest WSL2-Linux-Kernel release
Write-Host "Downloading the latest WSL2-Linux-Kernel release" -ForegroundColor Green
$kernelPath = "$env:TEMP\kernel.tar.gz"
Invoke-WebRequest -Uri $downloadUrl -OutFile $kernelPath

# Convert the kernel path to a WSL path
$kernelPathWSL = Convert-PathToWSL($kernelPath)

# Display the download path
Write-Host "WSL2-Linux-Kernel downloaded to $kernelPath" -ForegroundColor Green
Write-Host "WSL2-Linux-Kernel download path in WSL $kernelPathWSL" -ForegroundColor Green

# Convert the custom config path to a WSL path
if ($customConfig) {
    $customConfig = Convert-PathToWSL($customConfig)
    Write-Host "Custom config path in WSL $customConfig" -ForegroundColor Green
}

# Copy the downloaded .tar.gz to the WSL system distro
wsl --system --user root cp $kernelPathWSL ~/kernel.tar.gz

# Extract the downloaded .tar.gz in the system distro
wsl --system --user root tar -xzf ~/kernel.tar.gz -C ~

# Detect if the current device is x86_64 or arm64
$architecture = wsl --system --user root uname -m

# Build the kernel using the appropriate config
$kernelConfig = if ($customConfig) { $customConfig } elseif ($architecture -eq 'x86_64') { 'Microsoft/config-wsl' } elseif ($architecture -eq 'aarch64') { 'Microsoft/config-wsl-arm64' } else { Write-Error "Unsupported architecture: $architecture"; exit 1 }
$cores = wsl --system nproc
if ($skipClean) {
    Write-Host "Skipping kernel clean" -ForegroundColor Green
} else {
    Write-Host "Cleaning kernel build" -ForegroundColor Green
    wsl --system --user root make -C ~/WSL2-Linux-Kernel-* clean
}
Write-Host "Building kernel with $cores cores" -ForegroundColor Green
wsl --system --user root sh -c "yes '' | make -C ~/WSL2-Linux-Kernel-* KCONFIG_CONFIG=$kernelConfig -j$cores"

# Convert USERPROFILE to a WSL path
$userProfileWSL = Convert-PathToWSL($env:USERPROFILE)

# Copy the built kernel to %USERHOME%
Write-Host "Copying the built kernel to $env:USERHOME" -ForegroundColor Green
if ($architecture -eq 'x86_64') {
    wsl --system --user root sh -c "cp /root/WSL2-Linux-Kernel-*/arch/x86/boot/bzImage $userProfileWSL/wsl2kernel"
} elseif ($architecture -eq 'aarch64') {
    wsl --system --user root sh -c "cp /root/WSL2-Linux-Kernel-*/arch/arm64/boot/Image $userProfileWSL/wsl2kernel"
} else {
    Write-Error "Unsupported architecture: $architecture"
    exit 1
}

# Verify wsl2kernel exists
if (!(Test-Path -Path "$env:USERPROFILE/wsl2kernel")) {
    Write-Error "The kernel was not copied to Windows successfully"
    Exit 1
}

# Create or update %USERHOME%/.wslconfig to point to the new kernel
if (!(Test-Path -Path $wslConfigPath)) {
    Write-Host "Creating $wslConfigPath" -ForegroundColor Green
    $wslKernelPath = "$(($env:USERPROFILE -replace '\\', '/') -replace '/', '\\')\\wsl2kernel"
    $wslConfig = @"
[wsl2]
kernel=$wslKernelPath
"@
    $wslConfig | Out-File -FilePath $wslConfigPath -Encoding ascii
} else {
    Write-Host "Updating $wslConfigPath" -ForegroundColor Green
    $wslKernelPath = "$(($env:USERPROFILE -replace '\\', '/') -replace '/', '\\')\\wsl2kernel"
    $wslConfig = Get-Content -Path $wslConfigPath
    $kernelLineIndex = $wslConfig | Select-String -Pattern 'kernel=' | Select-Object LineNumber
    if ($kernelLineIndex) {
        $wslConfig[$kernelLineIndex.LineNumber - 1] = "kernel=$wslKernelPath"
    } else {
        $wslConfig += "kernel=$wslKernelPath"
    }
    $wslConfig | Out-File -FilePath $wslConfigPath -Encoding ascii
}

# Display message to restart WSL
Write-Host "Restart WSL to use the new kernel" -ForegroundColor Green
