import os, osproc, strutils, json, puppy

let tempDir = getEnv("TEMP")
let wslTempDir = "/mnt/" & tempDir[0].toLowerAscii() & tempDir[2..^1].replace("\\", "/")

proc runCommand(cmd: string): (int, string, string) =
  let result = execCmdEx(cmd, options = {poUsePath, poStdErrToStdOut})
  echo result.output
  return (result.exitCode, result.output, result.output)

proc downloadKernel() =
  
  # Get latest kernel version of Microsoft/WSL2-Linux-Kernel from GitHub API
  let response = get("https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest")
  let json = parseJson(response.body)
  let kernelVersion = json["tag_name"].str
  # Get download url for kernel tar.gz
  let downloadUrl = "https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/" & kernelVersion & ".tar.gz"
  # Use puppy library to download kernel tar.gz
  let download = get(downloadUrl)
  let kernelTar = open(tempDir & "/kernel.tar.gz", fmWrite)
  kernelTar.write(download.body)
  kernelTar.close()

let perfElfExists = fileExists("perf.elf")

if perfElfExists:
  let (output, exitCode) = execCmdEx("wsl.exe --system --user root ./perf.elf " & commandLineParams().join(" "))
  echo output
  if exitCode != 0:
    quit(exitCode)
else:
  echo "perf does not exist. Do you want to build and install perf? [Y/n]"
  let response = readLine(stdin)
  if response in ["", "Y", "y"]:
    echo "Installing perf"
    discard runCommand("wsl.exe --system --user root sh -c 'while true; do sleep 1000; done'")
    echo "Installing dependencies"
    discard runCommand("wsl.exe --system --user root tdnf install -y gcc glibc-devel make gawk tar kernel-headers binutils flex bison glibc-static diffutils elfutils-libelf-devel libnuma-devel libbabeltrace2-devel python3")
    echo "Downloading perf sources"
    downloadKernel()
    echo "Copying perf sources to WSL System Distro"
    discard runCommand("wsl --system --user root cp " & wslTempDir & "/kernel.tar.gz ~/kernel.tar.gz")
    echo "Extracting perf sources"
    discard runCommand("wsl --system --user root tar -xzf ~/kernel.tar.gz -C ~")
    echo "Building perf"
    discard runCommand("wsl --system --user root sh -c \"cd ~/WSL2-Linux-Kernel-* && make -C tools/perf LDFLAGS='-static'\"")
    echo "Copying perf to local directory"
    discard runCommand("wsl --system --user root cp ~/WSL2-Linux-Kernel-*/tools/perf/perf ./perf.elf")
    echo "Cleaning up"
    discard runCommand("wsl --system --user root pkill sleep")
    removeFile(getEnv("TEMP") & "/kernel.tar.gz")
    echo "perf installed: ", fileExists("perf.elf")
    let (output, exitCode) = execCmdEx("wsl.exe --system --user root ./perf.elf " & commandLineParams().join(" "))
    echo output
    if exitCode != 0:
      quit(exitCode)
  else:
    echo "Exiting..."