using System;
using System.IO;
using System.Text;

namespace XogentWingetUpdater.Services
{
    public class LoggingService
    {
        private readonly string _logDirectory;
        private readonly string _logFilePath;
        private readonly StringBuilder _logBuffer;

        public LoggingService()
        {
            var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            _logDirectory = Path.Combine(localAppData, "XOGENT", "WingetUpdater", "logs");
            
            // Ensure directory exists
            Directory.CreateDirectory(_logDirectory);
            
            // Create log file with timestamp
            var timestamp = DateTime.Now.ToString("yyyy-MM-dd-HHmmss");
            _logFilePath = Path.Combine(_logDirectory, $"updater-{timestamp}.log");
            
            _logBuffer = new StringBuilder();
            
            // Write initial log entry
            Log($"=== Winget Updater Started at {DateTime.Now:yyyy-MM-dd HH:mm:ss} ===");
        }

        public void Log(string message)
        {
            var logEntry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}";
            _logBuffer.AppendLine(logEntry);
            
            try
            {
                File.AppendAllText(_logFilePath, logEntry + Environment.NewLine);
            }
            catch (Exception ex)
            {
                // Silently fail if logging fails - don't break the application
                System.Diagnostics.Debug.WriteLine($"Failed to write log: {ex.Message}");
            }
        }

        public void LogError(string message, Exception? exception = null)
        {
            Log($"ERROR: {message}");
            if (exception != null)
            {
                Log($"Exception: {exception.GetType().Name} - {exception.Message}");
                Log($"Stack Trace: {exception.StackTrace}");
            }
        }

        public void LogWingetOutput(string output)
        {
            if (!string.IsNullOrWhiteSpace(output))
            {
                Log($"Winget: {output.Trim()}");
            }
        }

        public void LogCompletion(int successCount, int failureCount, TimeSpan duration)
        {
            Log($"=== Update Completed ===");
            Log($"Successful updates: {successCount}");
            Log($"Failed updates: {failureCount}");
            Log($"Duration: {duration.TotalSeconds:F2} seconds");
            Log($"=== Winget Updater Finished at {DateTime.Now:yyyy-MM-dd HH:mm:ss} ===");
        }

        public string GetLogFilePath() => _logFilePath;
    }
}

