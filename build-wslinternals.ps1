# Install ps2exe module if not already installed
if (-not (Get-Module -Name ps2exe -ListAvailable)) {
    Install-Module -Name ps2exe -Scope CurrentUser -Force
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