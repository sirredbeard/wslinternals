using System;
using System.Diagnostics;
using Microsoft.Win32;

public class Program
{
    public static void Main(string[] args)
    {
        bool winget = Array.Exists(args, arg => arg == "-winget");
        bool scoop = Array.Exists(args, arg => arg == "-scoop");
        bool wsl = Array.Exists(args, arg => arg == "-wsl");
        bool wslpr = Array.Exists(args, arg => arg == "-wslpr");

        var distros = GetInstalledDistros();

        foreach (var distro in distros)
        {
            if (distro == "docker-desktop" || distro == "docker-desktop-data" || distro == "podman-machine-default" || distro == "rancher-desktop" || distro == "rancher-desktop-data")
            {
                continue;
            }

            var output = RunCommand("wsl.exe", $"-d {distro} cat /etc/os-release | Select-String \"^ID=\"");
            var parts = output.Split('=');
            var id = parts.Length > 1 ? parts[1] : string.Empty;

            Console.WriteLine($"Updating {distro}");

            switch (id)
            {
                case "debian":
                case "ubuntu":
                    RunCommand("wsl.exe", $"-d {distro} -u root -- bash -c \"DEBIAN_FRONTEND=noninteractive apt-get update -y > /dev/null\"");
                    RunCommand("wsl.exe", $"-d {distro} -u root -- bash -c \"DEBIAN_FRONTEND=noninteractive apt-get upgrade -y > /dev/null\"");
                    break;
                case "fedora":
                case "rhel":
                case "almalinux":
                case "rocky":
                case "scientific":
                case "centos":
                    RunCommand("wsl.exe", $"-d {distro} -u root dnf update -y > $null");
                    break;
                case "alpine":
                    RunCommand("wsl.exe", $"-d {distro} -u root apk update > $null");
                    RunCommand("wsl.exe", $"-d {distro} -u root apk upgrade -y > $null");
                    break;
                case "suse":
                case "sles":
                    RunCommand("wsl.exe", $"-d {distro} -u root zypper dup -y > $null");
                    break;
                case "arch":
                    RunCommand("wsl.exe", $"-d {distro} -u root pacman -Sy archlinux-keyring --noconfirm > $null");
                    RunCommand("wsl.exe", $"-d {distro} -u root pacman-key --init > $null");
                    RunCommand("wsl.exe", $"-d {distro} -u root pacman -Syu --noconfirm > $null");
                    break;
                case "openEuler":
                    RunCommand("wsl.exe", $"-d {distro} -u root dnf update -y > $null");
                    break;
            }
        }

        if (winget)
        {
            RunCommand("winget", "update --all --include-unknown > $null");
        }

        if (scoop)
        {
            RunCommand("powershell", "-NonInteractive -NoProfile -Command \"scoop update *\" > $null 2>&1");
        }

        if (wsl)
        {
            RunCommand("powershell", "-NonInteractive -NoProfile -Command \"wsl.exe --update\" > $null 2>&1");
        }

        if (wslpr)
        {
            RunCommand("powershell", "-NonInteractive -NoProfile -Command \"wsl.exe --update --pre-release\" > $null 2>&1");
        }
    }

    private static string[] GetInstalledDistros()
    {
        RegistryKey lxssKey = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Lxss");
        var distroNames = lxssKey.GetSubKeyNames().Select(name =>
        {
            using var subKey = lxssKey.OpenSubKey(name);
            return subKey.GetValue("DistributionName").ToString();
        }).ToArray();
        return distroNames;
    }

    private static string RunCommand(string command, string arguments)
    {
        ProcessStartInfo startInfo = new ProcessStartInfo
        {
            FileName = command,
            Arguments = arguments,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };

        Process process = Process.Start(startInfo);
        process.WaitForExit();
        return process.StandardOutput.ReadToEnd();
    }
}