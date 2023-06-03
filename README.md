# A collection of some nifty WSL-related utilities

![Screenshot 2023-06-02 194607](https://github.com/sirredbeard/wslinternals/assets/33820650/7107bb48-eac8-4517-9cc5-1b579f20c5da)

## list-wsl

Provides a list of installed distributions, the official Linux distro name, the Linux distro version, the default user, systemd status, current state, and WSL version.

## wslctl

Allows WSL distros to be started on launch. The syntax follows that of systemctl:

```
wslctl enable pengwin
wslctl disable pengwin
wslctl restart pengwin
```

/prompts contains example AI prompts used to generate the first draft of these scripts, the final scripts got hand polished, but they are there to see