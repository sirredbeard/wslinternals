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
