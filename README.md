# A collection of some nifty WSL-related utilities

![Screenshot 2023-06-02 194607](https://github.com/sirredbeard/wslinternals/assets/33820650/419c5854-bb69-4d95-8f1f-6e8f0b8ac6b0)

## List of utilities

* **[list-wsl](https://github.com/sirredbeard/wslinternals#list-wsl)** - Lists detailed info on installed WSL distros
* **[wslctl](https://github.com/sirredbeard/wslinternals#wslctl)** - Start WSL distros on Windows startup
* **[wsl-dist-update](https://github.com/sirredbeard/wslinternals#wsl-dist-update)** - Update packages in all installed WSL distros
* **[wsl-reset](https://github.com/sirredbeard/wslinternals#wsl-reset)** - WSL troubleshooting tool, with soft, hard, and nuclear resets
* **[sysdistrowt](https://github.com/sirredbeard/wslinternals#sysdistrowt)** - Add the WSL System Distro to Windows Terminal
* **[build-wslinternals](https://github.com/sirredbeard/wslinternals#build-wslinternals)** - Build wslinternals

## list-wsl

Provides a list of installed distributions, the official Linux distro name, the Linux distro version, the default user, systemd status, current state, and WSL version.

## wslctl

Allows WSL distros to be started on Windows startup. The syntax follows that of systemctl:

`wslctl enable pengwin` - Start Pengwin on Windows startup.

`wslctl disable pengwin` - Disable starting Pengwin on Windows startup.

`wslctl restart pengwin` - Restart Pengwin running in background.

## wsl-dist-update

![image](https://github.com/sirredbeard/wslinternals/assets/33820650/e1b49c52-c87e-448d-9884-f296165060d6)

`wsl-dist-update` - Update all installed WSL distros.

`wsl-dist-update -winget` - Update all installed WSL distros and run winget update.

Run package updates on all installed WSL distros. Tested on: Pengwin, Fedora Remix for WSL, Ubuntu, Debian, openSUSE Tumbleweed, ArchWSL, AlmaLinux, Oracle Linux, Alpine, and the WSL System Distro.

To run wsl-dist-update as a service, copy wsl-dist-update.exe to a permanent location and run wsl-dist-update-sched.ps1, modifying the path to the .exe as needed.

## wsl-reset

A troubleshooting utility that resets the WSL 2 stack to various degrees.

`wsl-reset -reset` - Shuts down WSL, resets the WSL service, and installs any WSL updates, if available.

`wsl-reset -hardreset` - Shuts down WSL, stops the WSL service, uninstalls WSL, and re-installs WSL.

`wsl-reset -destrutivereset` - Shuts down WSL, restarts the WSL service, **unregisters all WSL distros**, stops the WSL service, uninstalls WSL, and re-installs WSL.

## sysdistrowt

![image](https://github.com/sirredbeard/wslinternals/assets/33820650/ea645f9e-af55-47f2-8ccf-5a14aa5e7d3b)

Adds the WSL System Distro (CBL-Mariner) to the Windows Terminal and/or Windows Terminal Preview profiles, for easier debugging.

## build-wslinternals

Builds wslinternals PowerShell scripts to .exe files using ps2exe. Must be run as Administrator on PowerShell 7 or on PowerShell 5. 
