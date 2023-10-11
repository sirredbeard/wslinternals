# A collection of some nifty WSL-related utilities

![Screenshot 2023-06-02 194607](https://github.com/sirredbeard/wslinternals/assets/33820650/419c5854-bb69-4d95-8f1f-6e8f0b8ac6b0)

## list-wsl

Provides a list of installed distributions, the official Linux distro name, the Linux distro version, the default user, systemd status, current state, and WSL version.

## wslctl

Allows WSL distros to be started on Windows startup. The syntax follows that of systemctl:

`wslctl enable pengwin`

`wslctl disable pengwin`

`wslctl restart pengwin`

## wsl-dist-update

Run package updates on all installed WSL distros. Tested on: Pengwin, Fedora Remix for WSL, Ubuntu, Debian, openSUSE Tumbleweed, ArchWSL, AlmaLinux, Oracle Linux, Alpine, and the WSL System Distro.

To run wsl-dist-update as a service, copy wsl-dist-update.exe to a permanent location and run wsl-dist-update-sched.ps1, modifying the path to the .exe as needed.

## wsl-reset

A troubleshooting utility that resets the WSL 2 stack to various degrees.

`wsl-reset --reset` - Shuts down WSL, resets the WSL service, and installs any WSL updates, if available.

`wsl-reset --hard-reset` - Shuts down WSL, stops the WSL service, uninstalls WSL, and re-installs WSL.

`wsl-reset --destrutive-reset` - Shuts down WSL, restarts the WSL service, **unregisters all WSL distros**, stops the WSL service, uninstalls WSL, and re-installs WSL.

## sysdistrowt

![image](https://github.com/sirredbeard/wslinternals/assets/33820650/ea645f9e-af55-47f2-8ccf-5a14aa5e7d3b)

Adds the WSL System Distro (CBL-Mariner) to the Windows Terminal and/or Windows Terminal Preview profiles, for easier debugging.

## build-wslinternals

Builds wslinternals PowerShell scripts to .exe files using ps2exe. Requires PowerShell 5.
