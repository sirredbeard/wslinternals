using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.Versioning;

// Define the WslDistribution class
public class WslDistribution
{
    public string Name { get; set; }
    public string State { get; set; }
    public int WSL { get; set; }
    public string Systemd { get; set; }
    public string DefaultUser { get; set; }
    public string DistroVersion { get; set; }
    public string LinuxDistro { get; set; }
}

// Define the Program class
public class Program
{
    // Limit Supported OS to Windows
    [SupportedOSPlatform("windows")]
    // Define the Main method
    public static void Main(string[] args)
    {
        // Declare a variable to store the GUID of the WSL distribution
        var defaultGuid = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss").GetValue("DefaultDistribution").ToString();

        // Declare a list to store the WSL distributions
        var wslDistributions = new List<WslDistribution>();

        // Print console header
        Console.WriteLine("{0,-20} {1,-20} {2,-20} {3,-10} {4,-10} {5,-10} {6,-5}", "WSL Distro", "Linux", "Version", "User", "Systemd", "State", "WSL Version");

        // Iterate through the subkeys of the WSL registry key
        foreach (var subKeyName in Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss").GetSubKeyNames())
        {
            var subKey = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss\" + subKeyName);
            var distributionName = subKey.GetValue("DistributionName").ToString();

            if (distributionName != "docker-desktop" && distributionName != "docker-desktop-data" && distributionName != "docker-desktop-runtime" && distributionName != "rancher-desktop" && distributionName != "rancher-desktop-data" && distributionName != "podman-machine-default")
            {
                var distribution = new WslDistribution
                {
                    Name = distributionName,
                    State = "Installed",
                    WSL = 2,
                    Systemd = "Disabled",
                    DefaultUser = "",
                    DistroVersion = "",
                    LinuxDistro = ""
                };

                var osRelease = RunWslCommand($"-d {distribution.Name} cat /etc/os-release");
                if (!string.IsNullOrEmpty(osRelease))
                {
                    var lines = osRelease.Split('\n');
                    distribution.LinuxDistro = GetPropertyFromOsRelease(lines, "PRETTY_NAME");
                    distribution.DistroVersion = GetPropertyFromOsRelease(lines, "VERSION");
                }

                var wslConf = RunWslCommand($"-d {distribution.Name} cat /etc/wsl.conf");
                distribution.Systemd = wslConf.Contains("systemd=true") ? "Enabled" : "Disabled";

                var defaultUid = subKey.GetValue("DefaultUid").ToString();
                var username = RunWslCommand($"-d {distribution.Name} -- id -un -- {defaultUid}");
                distribution.DefaultUser = username.Trim();

                wslDistributions.Add(distribution);
            }
        }
                // Print the distribution information
        foreach (var distribution in wslDistributions)
        {
        Console.WriteLine("{0,-20} {1,-20} {2,-20} {3,-10} {4,-10} {5,-10} {6,-5}", 
            Truncate(distribution.Name, 20), 
            Truncate(distribution.LinuxDistro, 20), 
            Truncate(distribution.DistroVersion, 20), 
            Truncate(distribution.DefaultUser, 10), 
            Truncate(distribution.Systemd, 10), 
            Truncate(distribution.State, 10), 
            Truncate(distribution.WSL.ToString(), 5));
        }
            
    }

    private static string RunWslCommand(string command)
    {
        var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "wsl.exe",
                Arguments = command,
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            }
        };
        process.Start();
        string result = process.StandardOutput.ReadToEnd();
        process.WaitForExit();
        return result;
    }

    private static string GetPropertyFromOsRelease(string[] lines, string propertyName)
    {
        foreach (var line in lines)
        {
            if (line.StartsWith(propertyName + "="))
            {
                return line.Split('=')[1].Replace("\"", "").Trim();
            }
        }
        return "";
    }

    private static string Truncate(string value, int maxLength)
    {
        if (string.IsNullOrEmpty(value)) return value;
        return value.Substring(0, Math.Min(value.Length, maxLength));
    }

}