using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using Newtonsoft.Json.Linq;

public class Program
{
    public static void Main(string[] args)
    {
        // Parse command line arguments
        var force = args.Contains("-force");
        var customConfig = args.Contains("-customConfig") ? args[Array.IndexOf(args, "-customConfig") + 1] : null;
        var skipClean = args.Contains("-skipClean");
        var revert = args.Contains("-revert");
        var check = args.Contains("-check");
        var wslConfigPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".wslconfig");

        // Check if the script is being run as administrator
        if (!IsAdministrator())
        {
            Console.Error.WriteLine("This script must be run as an administrator.");
            Environment.Exit(1);
        }

        // Revert to the default kernel if -revert is used
        if (revert)
        {
            Console.WriteLine("Reverting to the default kernel");
            if (File.Exists(wslConfigPath))
            {
                var wslConfig = File.ReadAllLines(wslConfigPath);
                var kernelLineIndex = Array.FindIndex(wslConfig, line => line.StartsWith("kernel="));
                if (kernelLineIndex != -1)
                {
                    wslConfig[kernelLineIndex] = "#kernel=";
                }
                File.WriteAllLines(wslConfigPath, wslConfig);
            }
            Environment.Exit(0);
        }

        // Check if a custom kernel is already set in .wslconfig and exit if -force is not used
        if (File.Exists(wslConfigPath) && File.ReadLines(wslConfigPath).Any(line => line.StartsWith("kernel=")) && !force)
        {
            Console.Error.WriteLine($"A custom kernel is set in {wslConfigPath}. Use -force to override.");
            Environment.Exit(1);
        }

        // Check if a custom kernel config is set and if it exists
        if (!string.IsNullOrEmpty(customConfig) && !File.Exists(customConfig))
        {
            Console.Error.WriteLine($"The custom kernel config file {customConfig} does not exist.");
            Environment.Exit(1);
        }
        else if (!string.IsNullOrEmpty(customConfig))
        {
            Console.WriteLine($"Using kernel custom config {customConfig}");
        }

        // Check current WSL kernel version
        var wslKernelVersion = RunCommand("wsl.exe", "--system --user root uname -r");
        Console.WriteLine($"Current installed WSL kernel version is {wslKernelVersion}");

        // Detect the latest release of WSL2-Linux-Kernel on GitHub
        var latestRelease = JObject.Parse(new CustomWebClient().DownloadString("https://api.github.com/repos/microsoft/WSL2-Linux-Kernel/releases/latest"));

        // Display the latest release version
        Console.WriteLine($"Latest WSL release version on GitHub is {latestRelease["tag_name"].ToString().Replace("linux-msft-wsl-", "")}");

        // Check if the latest release is newer than the current WSL kernel version
        if (latestRelease["tag_name"].ToString() == wslKernelVersion)
        {
            Console.WriteLine("The latest release of WSL2-Linux-Kernel is already installed");
            Environment.Exit(1);
        }

        if (check)
        {
            Environment.Exit(0);
        }

        // Run a persistent process in the wsl-system distro to prevent it from shutting down and resetting the environment
        var job = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "wsl.exe",
                Arguments = "--system --user root sh -c \"while true; do sleep 1000; done\"",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            }
        };
        job.Start();

        // Install kernel build dependencies in the WSL system distro
        Console.WriteLine("Installing kernel build dependencies in the WSL system distro");
        RunCommand("wsl.exe", "--system --user root tdnf install -y gcc glibc-devel kernel-headers make gawk tar bc perl python3 bison flex dwarves binutils diffutils elfutils-libelf-devel zlib-devel openssl-devel");

        // Form the kernel tar URL
        var downloadUrl = $"https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/{latestRelease["tag_name"]}.tar.gz";

        // Download the latest WSL2-Linux-Kernel release
        Console.WriteLine("Downloading the latest WSL2-Linux-Kernel release");
        var kernelPath = Path.Combine(Path.GetTempPath(), "kernel.tar.gz");
        new WebClient().DownloadFile(downloadUrl, kernelPath);

        // Convert the kernel path to a WSL path
        var kernelPathWSL = ConvertPathToWSL(kernelPath);

        // Display the download path
        Console.WriteLine($"WSL2-Linux-Kernel downloaded to {kernelPath}");
        Console.WriteLine($"WSL2-Linux-Kernel download path in WSL {kernelPathWSL}");

        // Convert the custom config path to a WSL path
        if (!string.IsNullOrEmpty(customConfig))
        {
            customConfig = ConvertPathToWSL(customConfig);
            Console.WriteLine($"Custom config path in WSL {customConfig}");
        }

        // Copy the downloaded .tar.gz to the WSL system distro
        RunCommand("wsl.exe", $"--system --user root cp {kernelPathWSL} ~/kernel.tar.gz");

        // Extract the downloaded .tar.gz in the system distro
        RunCommand("wsl.exe", "--system --user root tar -xzf ~/kernel.tar.gz -C ~");

        // Detect if the current device is x86_64 or arm64
        var architecture = RunCommand("wsl.exe", "--system --user root uname -m");

        // Build the kernel using the appropriate config
        var kernelConfig = !string.IsNullOrEmpty(customConfig) ? customConfig : (architecture == "x86_64" ? "Microsoft/config-wsl" : (architecture == "aarch64" ? "Microsoft/config-wsl-arm64" : null));
        if (kernelConfig == null)
        {
            Console.Error.WriteLine($"Unsupported architecture: {architecture}");
            Environment.Exit(1);
        }
        var cores = RunCommand("wsl.exe", "--system nproc");
        if (!skipClean)
        {
            Console.WriteLine("Cleaning kernel build");
            RunCommand("wsl.exe", "--system --user root make -C ~/WSL2-Linux-Kernel-* clean");
        }
        Console.WriteLine($"Building kernel with {cores} cores");
        RunCommand("wsl.exe", $"--system --user root sh -c \"yes '' | make -C ~/WSL2-Linux-Kernel-* KCONFIG_CONFIG={kernelConfig} -j{cores}\"");

        // Convert USERPROFILE to a WSL path
        var userProfileWSL = ConvertPathToWSL(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile));

        // Copy the built kernel to %USERHOME%
        Console.WriteLine($"Copying the built kernel to {Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)}");
        if (architecture == "x86_64")
        { 
            RunCommand("wsl.exe", $"--system --user root sh -c \"cp /root/WSL2-Linux-Kernel-*/arch/x86/boot/bzImage {userProfileWSL}/wsl2kernel\"");
        }
        else if (architecture == "aarch64")
        {
            RunCommand("wsl.exe", $"--system --user root sh -c \"cp /root/WSL2-Linux-Kernel-*/arch/arm64/boot/Image {userProfileWSL}/wsl2kernel\"");
        }
        else
        {
            Console.Error.WriteLine($"Unsupported architecture: {architecture}");
            Environment.Exit(1);
        }

        // Verify wsl2kernel exists
        if (!File.Exists(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "wsl2kernel")))
        {
            Console.Error.WriteLine("The kernel was not copied to Windows successfully");
            Environment.Exit(1);
        }

        // Create or update %USERHOME%/.wslconfig to point to the new kernel
        if (!File.Exists(wslConfigPath))
        {
            Console.WriteLine($"Creating {wslConfigPath}");
            var wslKernelPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "wsl2kernel").Replace("\\", "/");
            var wslConfig = $"[wsl2]\nkernel={wslKernelPath}\n";
            File.WriteAllText(wslConfigPath, wslConfig);
        }
        else
        {
            Console.WriteLine($"Updating {wslConfigPath}");
            var wslKernelPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "wsl2kernel").Replace("\\", "/");
            var wslConfig = File.ReadAllLines(wslConfigPath);
            var kernelLineIndex = Array.FindIndex(wslConfig, line => line.StartsWith("kernel="));
            if (kernelLineIndex != -1)
            {
                wslConfig[kernelLineIndex] = $"kernel={wslKernelPath}";
            }
            else
            {
                Array.Resize(ref wslConfig, wslConfig.Length + 1);
                wslConfig[^1] = $"kernel={wslKernelPath}";
            }
            File.WriteAllLines(wslConfigPath, wslConfig);
        }

        // Stop the persistent process in the wsl-system distro
        job.Kill();

        // Display message to restart WSL
        Console.WriteLine("Restart WSL to use the new kernel");
    }

    private static bool IsAdministrator()
    {
    var identity = System.Security.Principal.WindowsIdentity.GetCurrent();
    var principal = new System.Security.Principal.WindowsPrincipal(identity);
    return principal.IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator);
    }

    private static string RunCommand(string fileName, string arguments)
    {
        var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = arguments,
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            }
        };
        process.Start();
        string result = process.StandardOutput.ReadToEnd();
        process.WaitForExit();
        return result.Trim();
    }

    private static string ConvertPathToWSL(string path)
    {
        var drive = Path.GetPathRoot(path).Replace("\\", "").ToLower().Replace(":", "");
        var directory = path.Substring(Path.GetPathRoot(path).Length).Replace("\\", "/");
        return $"/mnt/{drive}/{directory}";
    }

    public class CustomWebClient : WebClient
{
    protected override WebRequest GetWebRequest(Uri address)
    {
        var request = base.GetWebRequest(address);
        if (request is HttpWebRequest httpRequest)
        {
            httpRequest.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0";
        }
        return request;
    }
}

}