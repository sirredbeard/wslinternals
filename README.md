# wslinternals - A collection of some nifty WSL-related utilities

![Screenshot 2023-06-02 194607](https://github.com/sirredbeard/wslinternals/assets/33820650/419c5854-bb69-4d95-8f1f-6e8f0b8ac6b0)

## Status

[![Build and Upload Artifacts on Release](https://github.com/sirredbeard/wslinternals/actions/workflows/build-on-release.yml/badge.svg)](https://github.com/sirredbeard/wslinternals/actions/workflows/build-on-release.yml)

# List of utilities

* **[list-wsl](https://github.com/sirredbeard/wslinternals#list-wsl)** - Lists detailed info on installed WSL distros
* **[wsl-update](https://github.com/sirredbeard/wslinternals#wsl-dist-update)** - Update packages in all installed WSL distros, also optionally WSL itself, winget, and Scoop
* **[wsl-kernel-build](https://github.com/sirredbeard/wslinternals#wsl-latest-kernel)** - Downloads, builds, and installs the latest kernel from WSL2-Linux-Kernel
* **[wsl-reset](https://github.com/sirredbeard/wslinternals#wsl-reset)** - WSL troubleshooting tool, with soft, hard, and destructive resets
* **[wslctl](https://github.com/sirredbeard/wslinternals#wslctl)** - Start WSL distros on Windows startup, like systemctl but for WSL distros
* **[sysdistro-wt](https://github.com/sirredbeard/wslinternals#sysdistrowt)** - Add the WSL System Distro to Windows Terminal, supports stable, Beta, and Canary builds of Windows Terminal.

# Installation

Scoop:

`scoop install wslinternals`

winget:

`winget install sirredbeard.wslinternals`

## list-wsl
✅ Refactored to .NET, building, and tested

![image](https://github.com/sirredbeard/wslinternals/assets/33820650/ab1f68b0-c2e5-4e0e-bccd-2c5bcf212a1a)

Provides a list of installed distributions, the official Linux distro name, the Linux distro version, the default user, systemd status, current state, and WSL version.

## wsl-update
✅ Refactored to .NET, building, and tested

![image](https://github.com/sirredbeard/wslinternals/assets/33820650/e1b49c52-c87e-448d-9884-f296165060d6)

`wsl-update` - Update all installed WSL distros.

Options:

    --winget - Also run Winget update.

    --scoop - Also run Scoop update.

    --wsl - Also update Windows Subsystem for Linux.

    --wslpr - Also update Windows Subsystem for Linux Pre-Release.

Run package updates on all installed WSL distros. Tested on: Pengwin, Fedora Remix for WSL, Ubuntu, Debian, openSUSE Tumbleweed, ArchWSL, AlmaLinux, Oracle Linux, Alpine, and OpenEuler.

## wsl-kernel-build
🛑 Refactored to .NET, still being debugged

![image](https://github.com/sirredbeard/wslinternals/assets/33820650/6ddbda88-da15-4d5d-896a-b42e44503e8b)

Downloads, builds, and installs the latest kernel release from WSL2-Linux-Kernel as a custom kernel in WSL2. This is occasionally newer than the version available through `wsl.exe --update`. The kernel is built in and exported from the immutable WSL2 System Distro image (powered by CBL-Mariner aka Azure Linux OS) so that no dependencies have to be installed in your WSL distros and the process is the same regardless of what WSL distros you have installed.

`wsl-kernel-build` - Run wsl-latest-kernel.

`wsl-kernel-build --check` - Check for an available kernel updates.

`wsl-kernel-build --force` - Overwrites the existing custom kernel.

`wsl-kernel-build --customconfig kernelconfig` - Build the kernel with a custom kernel config file. Expects a Windows path.

`wsl-kernel-build --revert` - Reverts to the default stock WSL2 kernel.

## wsl-reset 
✅ Refactored to .NET, building, and tested

A troubleshooting utility that resets the WSL 2 stack to various degrees.

`wsl-reset --reset` - Shuts down WSL and stops WSL services.

`wsl-reset --hardreset` - Shuts down WSL, stops WSL services, uninstalls WSL, and re-installs WSL.

`wsl-reset --destructivereset` - Shuts down WSL, restarts the WSL service, **unregisters all WSL distros**, stops the WSL service, uninstalls WSL, and re-installs WSL.

## wslctl
🛑 Refactored to .NET, still being debugged

Allows WSL distros to be started on Windows startup. The syntax follows that of systemctl:

`wslctl enable pengwin` - Start Pengwin on Windows startup.

`wslctl disable pengwin` - Disable starting Pengwin on Windows startup.

`wslctl restart pengwin` - Restart Pengwin running in background.

## sysdistro-wt
🛑 Refactored to .NET, still being debugged

![image](https://github.com/sirredbeard/wslinternals/assets/33820650/ea645f9e-af55-47f2-8ccf-5a14aa5e7d3b)

Adds the WSL System Distro to the Windows Terminal and/or Windows Terminal Preview profiles, for easier debugging. Note that the WSL System Distro is immutable. Once you close the session, it will revert back to the standard image installed with WSL2, and all changes will be lost.

# License

wslinternals is licensed Apache 2.0

# WSL Community

Join the WSL community Telegram at [WSL.community](https://wsl.community)
