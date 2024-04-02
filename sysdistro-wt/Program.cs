using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Newtonsoft.Json.Linq;

public class Program
{
    public static void Main()
    {
        var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var packagesPath = Path.Combine(localAppData, "Packages");

        var terminalPaths = new[]
        {
            "Microsoft.WindowsTerminal_*",
            "Microsoft.WindowsTerminalPreview_*",
            "Microsoft.WindowsTerminalCanary_*"
        }
        .Select(pattern => Directory.GetDirectories(packagesPath, pattern).FirstOrDefault())
        .Where(path => path != null)
        .ToArray();

        if (terminalPaths.Length == 0)
        {
            Console.WriteLine("Windows Terminal is not installed.");
            return;
        }

        var wslProfile = new JObject
        {
            ["name"] = "WSL System Distro",
            ["commandline"] = "wsl.exe -u root --system",
            ["hidden"] = false,
            ["guid"] = Guid.NewGuid().ToString("B"),
            ["icon"] = @"C:\Windows\System32\wsl.exe",
            ["startingDirectory"] = ""
        };

        foreach (var terminalPath in terminalPaths)
        {
            var terminalName = Path.GetFileName(terminalPath).Replace("Microsoft.", "").Replace("_8wekyb3d8bbwe", "");
            Console.WriteLine($"{terminalName} is installed.");

            var settingsPath = Path.Combine(terminalPath, "LocalState", "settings.json");
            if (!File.Exists(settingsPath))
            {
                Console.WriteLine($"{terminalName} settings.json not found, creating...");
                CreateSettingsFile(terminalName, settingsPath);
            }

            var settings = JObject.Parse(File.ReadAllText(settingsPath));
            var profiles = (JArray)settings["profiles"]["list"];
            profiles = new JArray(profiles.Where(profile => (string)profile["name"] != (string)wslProfile["name"]));
            profiles.Add(wslProfile);
            settings["profiles"]["list"] = profiles;

            File.WriteAllText(settingsPath, settings.ToString());
            Console.WriteLine($"{terminalName} settings.json updated.");
        }
    }

    private static void CreateSettingsFile(string terminalName, string settingsPath)
    {
        var terminalExePath = Directory.GetDirectories(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), $"WindowsApps\\Microsoft.{terminalName}_1*", SearchOption.AllDirectories).FirstOrDefault();
        if (terminalExePath == null)
        {
            Console.WriteLine($"Could not find {terminalName} executable path.");
            return;
        }

        var terminalExe = Path.Combine(terminalExePath, "wt.exe");
        var terminalProcess = Process.Start(terminalExe);
        if (terminalProcess == null)
        {
            Console.WriteLine($"Could not start {terminalName} process.");
            return;
        }

        System.Threading.Thread.Sleep(1000);
        terminalProcess.Kill();
    }
}