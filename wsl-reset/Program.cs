using System;
using System.Diagnostics;
using System.Linq;
using System.Security.Principal;
using Microsoft.Win32;
using System.ServiceProcess;
using System.Diagnostics.CodeAnalysis;

public class Program
{
    [SuppressMessage("Interoperability", "CA1416:Validate platform compatibility", Justification = "This application is intended to run only on Windows.")]
    public static void Main(string[] args)
    {
        bool reset = args.Contains("--reset");
        bool hardReset = args.Contains("--hardReset");
        bool destructiveReset = args.Contains("--destructiveReset");
        bool LxssManagerRunning = false;
        bool WslServiceRunning = false;

        // Check if the script is being run as an administrator
        if (!IsAdministrator())
        {
            Console.Error.WriteLine("This script must be run as an administrator.");
            Environment.Exit(1);
        }

        // Check if LxssManager exists, is running, and give it's status
        try
        {
            ServiceController lxssManager = new ServiceController("LxssManager");
            if (lxssManager.Status == ServiceControllerStatus.Running)
            {
                Console.WriteLine("LxssManager, the legacy WSL 1 service, is running.");
                // Set LxssManagerRunning to true
                LxssManagerRunning = true;
            }
            else
            {
                Console.WriteLine("LxssManager, the legacy WSL 1 service, is not running.");
            }
        }
        catch (InvalidOperationException)
        {
            Console.WriteLine("LxssManager, the legacy WSL 1 service, does not exist.");
        }

        // Check if WSL Service is running and give it's status
        ServiceController wslService = new ServiceController("WSL Service");
        if (wslService.Status == ServiceControllerStatus.Running)
        {
            Console.WriteLine("WSL Service, the WSL 2 service, is running.");
            // Set WslServiceRunning to true
            WslServiceRunning = true;
        }
        else
        {
            Console.WriteLine("WSL Service, the WSL 2 service, is not running.");
        }


        if (destructiveReset)
        {
            Console.WriteLine("Unregistering all WSL distros...");
            UnregisterAllDistros();
        }

        if (reset || hardReset || destructiveReset)
        {
            Console.WriteLine("Shutting down WSL...");
            RunCommand("wsl.exe", "--shutdown");
            // If LxssManager is running, stop it with StopService
            if (LxssManagerRunning)
            {
                Console.WriteLine("Stopping LxssManager Service...");
                StopService("LxssManager");
            }
            // If WslService is running, stop it with StopService
            if (WslServiceRunning)
            {
                Console.WriteLine("Stopping WSL Service...");
                StopService("WSL Service");
            }
        }
        
        if (hardReset || destructiveReset)
        {
            // Reset the WSL feature
            Console.WriteLine("Resetting WSL feature...");
            RunCommand("dism.exe", "/online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /quiet /norestart");
            RunCommand("dism.exe", "/online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /quiet /all /norestart");

            // Reset the Virtual Machine Platform feature
            Console.WriteLine("Resetting Virtual Machine Platform feature...");
            RunCommand("dism.exe", "/online /disable-feature /featurename:VirtualMachinePlatform /quiet /norestart");
            RunCommand("dism.exe", "/online /enable-feature /featurename:VirtualMachinePlatform /quiet /all /norestart");

            // Reset the Hyper-V feature
            Console.WriteLine("Resetting Hyper-V feature...");
            RunCommand("dism.exe", "/online /disable-feature /featurename:Microsoft-Hyper-V-All /quiet /norestart");
            RunCommand("dism.exe", "/online /enable-feature /featurename:Microsoft-Hyper-V-All /quiet /all /norestart");

            Console.WriteLine("Please restart your computer to complete the reset.");
        }
    
        
        if (!reset && !hardReset && !destructiveReset)
        {
            Console.Error.WriteLine("This script must be run with either --reset, --hardReset, or --destructiveReset.");
            Environment.Exit(1);
        }


    }

    [SuppressMessage("Interoperability", "CA1416:Validate platform compatibility", Justification = "This application is intended to run only on Windows.")]
    private static bool IsAdministrator()
    {
        WindowsIdentity identity = WindowsIdentity.GetCurrent();
        WindowsPrincipal principal = new WindowsPrincipal(identity);
        return principal.IsInRole(WindowsBuiltInRole.Administrator);
    }

    [SuppressMessage("Interoperability", "CA1416:Validate platform compatibility", Justification = "This application is intended to run only on Windows.")]
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

    [SuppressMessage("Interoperability", "CA1416:Validate platform compatibility", Justification = "This application is intended to run only on Windows.")]
    private static void StopService(string serviceName)
    {
        ServiceController service = new ServiceController(serviceName);
        try
        {
            service.Stop();
            service.WaitForStatus(ServiceControllerStatus.Stopped);
        }
        catch (Exception)
        {
            // Print message that service could not be stopped
            Console.Error.WriteLine($"Could not stop {serviceName} service.");
        }
}

    [SuppressMessage("Interoperability", "CA1416:Validate platform compatibility", Justification = "This application is intended to run only on Windows.")]
    private static void UnregisterAllDistros()
    {
        RegistryKey lxssKey = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Lxss");
        foreach (string subKeyName in lxssKey.GetSubKeyNames())
        {
            RegistryKey subKey = lxssKey.OpenSubKey(subKeyName);
            string distroName = subKey.GetValue("DistributionName")?.ToString();
            if (distroName != null)
            {
                RunCommand("wsl.exe", $"--unregister {distroName}");
            }
        }
    }
}