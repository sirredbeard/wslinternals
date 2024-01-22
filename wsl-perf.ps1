# Function to convert a Windows path to a WSL path
function Convert-PathToWSL($path) {
    return "/mnt/" + ($path -replace ":", "").Replace("\", "/").ToLower()
}

# Set the path to the perf.elf file
$perfElfPath = "./perf.elf"

# Get current directory
$currentDirectory = (Get-Location).Path

# Convert the current directory to a WSL path
$currentDirectoryWSL = Convert-PathToWSL($currentDirectory)

# Check if perf.elf exists
if (Test-Path $perfElfPath) {
    $arguments = "--system", "--user", "root", $perfElfPath
    $isExe = (Get-Process -Id $PID).ProcessName -eq 'wsl-perf'
    foreach ($arg in $args) {
        if ($isExe -and $arg -match '^--') {
            $arg = '-' + $arg
        }
        $arguments += , $arg
    }
    & wsl.exe $arguments
    
    # Set the exit code to the exit code of the wsl.exe process
    exit $LASTEXITCODE
    } else {
    Write-Output "perf.elf not found"
    $userInput = Read-Host -Prompt 'Do you want to build perf? (Y/N)'
    if ($userInput -eq 'Y') {
        Write-Output 'Building perf.elf...'
        
        # Run a persistent process in the wsl-system distro to prevent it from shutting down and resetting the environment
        $job = Start-Job -ScriptBlock {
            wsl --system --user root sh -c "while true; do sleep 1000; done"
        }

        # Install kernel build dependencies in the WSL system distro
        Write-Host "Installing perf build dependencies in the WSL system distro" -ForegroundColor Green
        wsl --system --user root tdnf install -y gcc glibc-devel make gawk tar kernel-headers binutils flex bison glibc-static diffutils elfutils-libelf-devel libnuma-devel libbabeltrace2-devel python3

        # Detect the latest release of WSL2-Linux-Kernel on GitHub
        $latestRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest'
        Write-Host "Latest perf release version on GitHub is $($latestRelease.tag_name.Replace('linux-msft-wsl-', ''))" -ForegroundColor Green
        
        # Download the latest perf release
        Write-Host "Downloading latest perf release" -ForegroundColor Green
        $downloadUrl = "https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/$($latestRelease.tag_name).tar.gz"
        $kernelPath = "$env:TEMP\kernel.tar.gz"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $kernelPath
        Write-Host $downloadUrl "downloaded to" $kernelPath -ForegroundColor Green

        # Copy the downloaded .tar.gz to the WSL system distro
        Write-Host "Copying sources to the WSL system distro" -ForegroundColor Green
        $kernelPathWSL = Convert-PathToWSL($kernelPath)
        wsl --system --user root cp $kernelPathWSL ~/kernel.tar.gz

        # Extract the downloaded .tar.gz in the system distro
        Write-Host "Extracting sources in the WSL system distro" -ForegroundColor Green
        wsl --system --user root tar -xzf ~/kernel.tar.gz -C ~

        # Detect if the current device is x86_64 or arm64
        Write-Host "Detecting architecture" -ForegroundColor Green
        $architecture = wsl --system --user root uname -m
        Write-Host "Architecture is $architecture" -ForegroundColor Green

        # Build perf
        Write-Host "Building perf" -ForegroundColor Green
        wsl --system --user root sh -c "cd ~/WSL2-Linux-Kernel-* && make -C tools/perf LDFLAGS='-static'"

        # Copy perf.elf to the current directory
        Write-Host "Copying perf.elf to the current directory" -ForegroundColor Green
        $perfElfPathWSL = "~/WSL2-Linux-Kernel-*/tools/perf/perf"
        wsl --system --user root cp $perfElfPathWSL $currentDirectoryWSL/perf.elf

        # Stop the persistent process in the WSL System distro
        Stop-Job -Job $job

        # Delete the downloaded kernel.tar.gz
        Write-Host "Deleting downloaded sources" -ForegroundColor Green
        Remove-Item $kernelPath

        # Confirm perf.elf exists
        if (Test-Path $perfElfPath) {
            Write-Host "perf.elf built successfully" -ForegroundColor Green
            $arguments = "--system", $perfElfPath
            $arguments += $ScriptArgs
            # Run perf.elf in the wsl-system distro with the provided arguments
            & wsl.exe $arguments
        } else {
            Write-Output "perf.elf not found"
            exit
        }


    } else {
        exit
    }
}