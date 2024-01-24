# Install ps2exe module if not already installed
if (-not (Get-Module -Name ps2exe -ListAvailable)) {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Install-Module -Name ps2exe -Scope CurrentUser -Force
}

# Install Scoop and Nim if not already installed
if (-not (Get-Command nim -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    scoop install nim
    nimble update -y
    nimble install puppy -y
}

# Check if cl.exe is available
if (-not (Get-Command cl -ErrorAction SilentlyContinue)) {
    Write-Host "cl.exe not found. Please install Visual Studio Build Tools 2019 or Visual Studio 2019 and try again."
    exit 1
}

# Check if Windows SDK is available
if (-not (Get-Command rc.exe -ErrorAction SilentlyContinue)) {
    Write-Host "rc.exe not found. Please install Windows SDK and try again."
    exit 1
}

# Create /bin/ subdirectory if it does not exist
if (-not (Test-Path -Path ".\bin\" -PathType Container)) {
    New-Item -ItemType Directory -Path ".\bin\"
}

# Get list of .ps1 files in current directory
$ps1Files = Get-ChildItem -Path . -Filter *.ps1

# Loop through each .ps1 file and convert to .exe using ps2exe
foreach ($ps1File in $ps1Files) {
    # Skip "build-wslinternals.ps1" and "wsl-dist-update-sched.ps1"
    if ($ps1File.Name -eq "build-wslinternals.ps1" -or $ps1File.Name -eq "wsl-dist-update-sched.ps1") {
        continue
    }
    $exeFile = ".\bin\" + $ps1File.Name.Replace(".ps1", ".exe")
    ps2exe -inputFile $ps1File.FullName -outputFile $exeFile
}

# Compile wslperf.nim to wsl-perf.exe
nim c -d:release -d:static -o:bin\wsl-perf.exe wslperf.nim