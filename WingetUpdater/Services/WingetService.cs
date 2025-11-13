using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using XogentWingetUpdater.Models;

namespace XogentWingetUpdater.Services
{
    public class WingetService
    {
        private readonly LoggingService _logger;
        private readonly string _wingetPath;

        public WingetService(LoggingService logger)
        {
            _logger = logger;
            _wingetPath = FindWingetPath();
        }

        private string FindWingetPath()
        {
            // Common winget locations
            var possiblePaths = new[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Microsoft", "WindowsApps", "winget.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "WindowsApps", "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe", "winget.exe"),
                "winget.exe" // In PATH
            };

            foreach (var path in possiblePaths)
            {
                if (File.Exists(path) || path == "winget.exe")
                {
                    _logger.Log($"Found winget at: {path}");
                    return path;
                }
            }

            _logger.LogError("Winget not found in common locations");
            return "winget.exe"; // Try PATH as fallback
        }

        public async Task<UpdateResult> UpdateAllPackagesAsync(IProgress<string>? progress = null, CancellationToken cancellationToken = default)
        {
            var result = new UpdateResult();
            var startTime = DateTime.Now;

            if (!IsWingetAvailable())
            {
                result.WingetAvailable = false;
                result.ErrorMessage = "Winget is not available on this system. Please install the App Installer from the Microsoft Store.";
                _logger.LogError(result.ErrorMessage);
                return result;
            }

            try
            {
                progress?.Report("Checking for available updates...");
                _logger.Log("Starting winget upgrade --all");

                var processInfo = new ProcessStartInfo
                {
                    FileName = _wingetPath,
                    Arguments = "upgrade --all --accept-source-agreements --accept-package-agreements --silent",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    StandardOutputEncoding = Encoding.UTF8,
                    StandardErrorEncoding = Encoding.UTF8
                };

                using var process = new Process { StartInfo = processInfo };
                var outputBuilder = new StringBuilder();
                var errorBuilder = new StringBuilder();

                process.OutputDataReceived += (sender, e) =>
                {
                    if (!string.IsNullOrEmpty(e.Data))
                    {
                        outputBuilder.AppendLine(e.Data);
                        _logger.LogWingetOutput(e.Data);
                        
                        // Parse progress from output
                        var line = e.Data.Trim();
                        if (line.Contains("Found") || line.Contains("Upgrading") || line.Contains("Installing"))
                        {
                            progress?.Report(line);
                        }
                    }
                };

                process.ErrorDataReceived += (sender, e) =>
                {
                    if (!string.IsNullOrEmpty(e.Data))
                    {
                        errorBuilder.AppendLine(e.Data);
                        _logger.LogWingetOutput($"ERROR: {e.Data}");
                    }
                };

                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                await process.WaitForExitAsync(cancellationToken);

                var output = outputBuilder.ToString();
                var error = errorBuilder.ToString();

                result.Duration = DateTime.Now - startTime;

                // Parse results from output
                ParseWingetOutput(output, result);

                // 0x8A150011 = no updates available (signed integer: -1978335215)
                if (process.ExitCode != 0 && (uint)process.ExitCode != 0x8A150011)
                {
                    result.FailureCount++;
                    result.ErrorMessage = $"Winget exited with code {process.ExitCode}";
                    if (!string.IsNullOrEmpty(error))
                    {
                        result.ErrorMessage += $": {error}";
                    }
                    _logger.LogError(result.ErrorMessage);
                }
                else
                {
                    progress?.Report("Updates completed successfully!");
                }

                _logger.LogCompletion(result.SuccessCount, result.FailureCount, result.Duration);
            }
            catch (Exception ex)
            {
                result.FailureCount++;
                result.ErrorMessage = ex.Message;
                _logger.LogError("Exception during winget update", ex);
            }

            return result;
        }

        private void ParseWingetOutput(string output, UpdateResult result)
        {
            if (string.IsNullOrWhiteSpace(output))
                return;

            var lines = output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            
            // Count successful upgrades
            var upgradePattern = new Regex(@"Successfully installed|Successfully upgraded", RegexOptions.IgnoreCase);
            var foundPattern = new Regex(@"Found (\d+) package", RegexOptions.IgnoreCase);
            
            foreach (var line in lines)
            {
                if (upgradePattern.IsMatch(line))
                {
                    result.SuccessCount++;
                    // Extract package name if possible
                    var packageMatch = Regex.Match(line, @"(\S+)\s+\[.*?\]");
                    if (packageMatch.Success)
                    {
                        result.UpdatedPackages.Add(packageMatch.Groups[1].Value);
                    }
                }
                
                var foundMatch = foundPattern.Match(line);
                if (foundMatch.Success)
                {
                    int.TryParse(foundMatch.Groups[1].Value, out int total);
                    result.TotalPackages = total;
                }
            }

            // If no explicit success count, check for "No applicable updates" message
            if (result.SuccessCount == 0 && output.Contains("No applicable updates", StringComparison.OrdinalIgnoreCase))
            {
                result.SuccessCount = 0; // No updates needed is still success
            }
        }

        private bool IsWingetAvailable()
        {
            try
            {
                var processInfo = new ProcessStartInfo
                {
                    FileName = _wingetPath,
                    Arguments = "--version",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using var process = Process.Start(processInfo);
                if (process != null)
                {
                    process.WaitForExit(5000);
                    return process.ExitCode == 0;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError("Failed to verify winget availability", ex);
            }

            return false;
        }
    }
}

