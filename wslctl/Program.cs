using System;
using System.Diagnostics;
using System.Linq;
using System.Security.Principal;
using Microsoft.Win32;
using Microsoft.Win32.TaskScheduler;

public class Program
{
    public static void Main(string[] args)
    {
        // Check if the script is being run as administrator
        if (!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator))
        {
            Console.Error.WriteLine("This script must be run as an administrator.");
            Environment.Exit(1);
        }

        // Parse command line arguments
        var operation = args[0];
        var distroName = args[1];

        // Check if a WSL distro name was specified
        if (string.IsNullOrEmpty(distroName))
        {
            Console.Error.WriteLine("A WSL distro name must be specified.");
            Environment.Exit(1);
        }

        // If the distro name is Pengwin, use WLinux instead
        if (distroName == "Pengwin")
        {
            distroName = "WLinux";
        }

        // Check if the specified WSL distro exists
        var lxssKey = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Lxss");
        var distroGuids = lxssKey.GetSubKeyNames();
        var distroGuid = distroGuids.FirstOrDefault(guid =>
            (string)lxssKey.OpenSubKey(guid).GetValue("DistributionName") == distroName);

        if (string.IsNullOrEmpty(distroGuid))
        {
            Console.Error.WriteLine("The specified WSL distro does not exist.");
            Environment.Exit(1);
        }

        // Check if the specified WSL distro is enabled
        var taskName = $"Start {distroName} at startup";
        var taskPath = @"\Microsoft\Windows\WSL";
        using var ts = new TaskService();
        var task = ts.FindTask(taskName);

        if (operation == "enable")
        {
            if (task != null)
            {
                Console.Error.WriteLine("The specified WSL distro has already been enabled.");
                Environment.Exit(1);
            }

            var td = ts.NewTask();
            td.RegistrationInfo.Description = taskName;
            td.Triggers.Add(new BootTrigger());
            td.Actions.Add(new ExecAction("wsl.exe", $"-d {distroGuid}"));
            ts.RootFolder.RegisterTaskDefinition(taskName, td);
            Console.WriteLine("The specified WSL distro has been enabled.");
        }
        else if (operation == "disable")
        {
            if (task == null)
            {
                Console.Error.WriteLine("The specified WSL distro is not enabled.");
                Environment.Exit(1);
            }

            ts.RootFolder.DeleteTask(taskName);
            Console.WriteLine("The specified WSL distro has been disabled.");
        }
        else if (operation == "restart")
        {
            if (task == null)
            {
                Console.Error.WriteLine("The specified WSL distro is not enabled.");
                Environment.Exit(1);
            }

            task.Enabled = false;
            task.Enabled = true;
            Process.Start("wsl.exe", $"-d {distroName} -u root -- shutdown -r now");
        }
    }
}