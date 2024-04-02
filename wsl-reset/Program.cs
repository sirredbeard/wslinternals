using System;
using System.Diagnostics;
using System.Linq;
using System.Security.Principal;
using Microsoft.Win32;
using System.ServiceProcess;

public class Program
{
    public static void Main(string[] args)
    {
        bool reset = args.Contains("-reset");
        bool hardReset = args.Contains("-hardReset");
        bool destructiveReset = args.Contains("-destructiveReset");

        if (!IsAdministrator())
        {
            Console.Error.WriteLine("This script must be run as an administrator.");
            Environment.Exit(1);
        }

        if (reset)
        {
            RunCommand("wsl.exe", "--shutdown");
            RestartService("Windows Subsystem for Linux");
            RunCommand("wsl.exe", "--update");
            Console.WriteLine("WSL has been shutdown, Windows service restarted, and updated, if applicable.");
        }
        else if (hardReset)
        {
            RunCommand("wsl.exe", "--shutdown");
            StopService("Windows Subsystem for Linux");
            RunCommand("wsl.exe", "--install --no-launch --no-distribution");
            Console.WriteLine("WSL has been shutdown and re-installed.");
        }
        else if (destructiveReset)
        {
            RunCommand("wsl.exe", "--shutdown");
            RestartService("Windows Subsystem for Linux");
            UnregisterAllDistros();
            RunCommand("wsl.exe", "--install --no-launch --no-distribution");
            Console.WriteLine("WSL has been shutdown, all distros unregistered, and WSL has been re-installed.");
        }
        else
        {
            Console.Error.WriteLine("This script must be run with either -reset, -hardReset, or -destructiveReset.");
            Environment.Exit(1);
        }
    }

    private static bool IsAdministrator()
    {
        WindowsIdentity identity = WindowsIdentity.GetCurrent();
        WindowsPrincipal principal = new WindowsPrincipal(identity);
        return principal.IsInRole(WindowsBuiltInRole.Administrator);
    }

    private static void RunCommand(string command, string arguments)
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
    }

    private static void RestartService(string serviceName)
    {
        ServiceController service = new ServiceController(serviceName);
        service.Stop();
        service.WaitForStatus(ServiceControllerStatus.Stopped);
        service.Start();
        service.WaitForStatus(ServiceControllerStatus.Running);
    }

    private static void StopService(string serviceName)
    {
        ServiceController service = new ServiceController(serviceName);
        service.Stop();
        service.WaitForStatus(ServiceControllerStatus.Stopped);
    }

    private static void UnregisterAllDistros()
    {
        RegistryKey lxssKey = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Lxss");
        foreach (string subKeyName in lxssKey.GetSubKeyNames())
        {
            RegistryKey subKey = lxssKey.OpenSubKey(subKeyName);
            string distroName = subKey.GetValue("DistributionName").ToString();
            RunCommand("wsl.exe", $"--unregister {distroName}");
        }
    }
}