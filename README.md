# A collection of some nifty WSL-related utilities

![Screenshot 2023-06-02 194607](https://github.com/sirredbeard/wslinternals/assets/33820650/419c5854-bb69-4d95-8f1f-6e8f0b8ac6b0)

## list-wsl

Provides a list of installed distributions, the official Linux distro name, the Linux distro version, the default user, systemd status, current state, and WSL version.

## wslctl

Allows WSL distros to be started on launch. The syntax follows that of systemctl:

```
wslctl enable pengwin
wslctl disable pengwin
wslctl restart pengwin
```

## wsl-reset

A troubleshooting utility that resets WSL to various degrees.

`wsl-reset --reset` - shuts down WSL, resets the WSL service, and installs any WSL updates, if available

`wsl-reset --hard-reset` - shuts down WSL, stops the WSL service, uninstalls WSL, and re-installs WSL

`wsl-reset --destrutive-reset` - shuts down WSL, restarts the WSL service, **unregisters all WSL distros**, stops the WSL service, uninstalls WSL, and re-installs WSL

## sysdistrowt

Adds the WSL System Distro (CBL-Mariner) to the Windows Terminal and/or Windows Terminal Preview profiles, for easier debugging.

### Misc

 /prompts folder contains example AI prompts used to generate the first draft of these scripts, the final scripts got hand polished, but they are there to see.