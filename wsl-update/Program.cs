using System;
using System.Diagnostics;
using Microsoft.Win32;

public class Program
{
    public static void Main(string[] args)
    {
        bool winget = Array.Exists(args, arg => arg == "--winget");
        bool scoop = Array.Exists(args, arg => arg == "--scoop");
        bool wsl = Array.Exists(args, arg => arg == "--wsl");
        bool wslpr = Array.Exists(args, arg => arg == "--wslpr");

        var distros = GetInstalledDistros();

        foreach (var distro in distros)
        {
            if (distro == "docker-desktop" || distro == "docker-desktop-data" || distro == "podman-machine-default" || distro == "rancher-desktop" || distro == "rancher-desktop-data")
            {
                continue;
            }

            var id = RunCommand("wsl.exe", $"-d {distro} awk -F= '/^ID=/{{print $2}}' /etc/os-release | tr -d '\"'").Trim();

            Console.WriteLine($"Updating {distro}");

            switch (id)
            {
                case "debian":
                case "ubuntu":
                    RunCommand("wsl.exe", $"-d {distro} -u root -- bash -c \"DEBIAN_FRONTEND=noninteractive apt-get update -y\"");
                    RunCommand("wsl.exe", $"-d {distro} -u root -- bash -c \"DEBIAN_FRONTEND=noninteractive apt-get upgrade -y\"");
                    break;
                case "fedora":
                case "rhel":
                case "almalinux":
                case "rocky":
                case "scientific":
                case "centos":
                    RunCommand("wsl.exe", $"-d {distro} -u root dnf update -y");
                    break;
                case "alpine":
                    RunCommand("wsl.exe", $"-d {distro} -u root apk update");
                    RunCommand("wsl.exe", $"-d {distro} -u root apk upgrade -y");
                    break;
                case "suse":
                case "sles":
                    RunCommand("wsl.exe", $"-d {distro} -u root zypper dup -y");
                    break;
                case "arch":
                    RunCommand("wsl.exe", $"-d {distro} -u root pacman -Sy archlinux-keyring --noconfirm");
                    RunCommand("wsl.exe", $"-d {distro} -u root pacman-key --init");
                    RunCommand("wsl.exe", $"-d {distro} -u root pacman -Syu --noconfirm");
                    break;
                case "openEuler":
                    RunCommand("wsl.exe", $"-d {distro} -u root dnf update -y");
                    break;
            }
        }

        if (winget)
        {
            Console.WriteLine("Updating Winget");
            RunCommand("winget", "update --all --include-unknown");
        }

        if (scoop)
        {
            Console.WriteLine("Updating Scoop");
            RunCommand("powershell", "-NonInteractive -NoProfile -Command scoop update *");
        }

        if (wsl)
        {
            Console.WriteLine("Updating WSL");
            RunCommand("powershell", "-NonInteractive -NoProfile -Command wsl.exe --update");
        }

        if (wslpr)
        {
            Console.WriteLine("Updating WSL Pre-Release");
            RunCommand("powershell", "-NonInteractive -NoProfile -Command wsl.exe --update --pre-release");
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