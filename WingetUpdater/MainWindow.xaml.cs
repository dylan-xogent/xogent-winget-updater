using System;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Threading;
using XogentWingetUpdater.Models;
using XogentWingetUpdater.Services;

namespace XogentWingetUpdater
{
    public partial class MainWindow : Window
    {
        private readonly LoggingService _logger;
        private readonly WingetService _wingetService;
        private CancellationTokenSource? _cancellationTokenSource;
        private bool _isUpdating = false;
        private int _totalPackages = 0;
        private int _currentPackage = 0;
        private DoubleAnimation? _rotationAnimation;

        public MainWindow()
        {
            InitializeComponent();

            _logger = new LoggingService();
            _wingetService = new WingetService(_logger);

            // Start updates immediately when window loads
            Loaded += MainWindow_Loaded;

            // Prevent closing during updates
            Closing += MainWindow_Closing;

            // Initialize rotation animation for status icon
            _rotationAnimation = new DoubleAnimation
            {
                From = 0,
                To = 360,
                Duration = TimeSpan.FromSeconds(2),
                RepeatBehavior = RepeatBehavior.Forever
            };
        }

        private void MainWindow_Loaded(object sender, RoutedEventArgs e)
        {
            // Start update process asynchronously
            _ = StartUpdateProcessAsync();
        }

        private async Task StartUpdateProcessAsync()
        {
            if (_isUpdating)
                return;

            _isUpdating = true;
            _cancellationTokenSource = new CancellationTokenSource();

            // Start rotation animation
            StartIconAnimation();

            try
            {
                UpdateStatus("Checking for available updates...", "⟳");
                UpdateSubStatus("Connecting to winget package manager...");
                UpdateCurrentPackage("Initializing system scan...");
                UpdateProgressDetails("Starting winget update process...");

                var progress = new Progress<string>(message =>
                {
                    Dispatcher.Invoke(() =>
                    {
                        if (!string.IsNullOrEmpty(message))
                        {
                            UpdateProgressDetails(message);
                            UpdateCurrentPackage(message);
                        }
                    });
                });

                var result = await _wingetService.UpdateAllPackagesAsync(progress, _cancellationTokenSource.Token);

                Dispatcher.Invoke(() =>
                {
                    StopIconAnimation();
                    HandleUpdateResult(result);
                });
            }
            catch (OperationCanceledException)
            {
                Dispatcher.Invoke(() =>
                {
                    StopIconAnimation();
                    UpdateStatus("Update cancelled", "⚠");
                    UpdateSubStatus("Process was cancelled by system");
                    UpdateProgressDetails("The update process was cancelled.");
                });
            }
            catch (Exception ex)
            {
                _logger.LogError("Unexpected error during update process", ex);
                Dispatcher.Invoke(() =>
                {
                    StopIconAnimation();
                    UpdateStatus("Error occurred", "✗");
                    UpdateSubStatus("An unexpected error occurred");
                    UpdateProgressDetails($"ERROR: {ex.Message}");
                });
            }
            finally
            {
                _isUpdating = false;

                // Auto-close after a brief delay
                _ = Task.Run(async () =>
                {
                    await Task.Delay(3000); // 3 second delay to show completion
                    Dispatcher.Invoke(() => Close());
                });
            }
        }

        private void HandleUpdateResult(UpdateResult result)
        {
            if (!result.WingetAvailable)
            {
                UpdateStatus("Winget Not Available", "⚠");
                UpdateSubStatus("Package manager not found on system");
                UpdateCurrentPackage("Winget is not installed or not accessible");
                UpdateProgressDetails(result.ErrorMessage ?? "Winget is not installed on this system.");
                SetProgressBar(false, 0);
                UpdatePercentage(0);
                FooterText.Text = "Please install App Installer from Microsoft Store";
                return;
            }

            _totalPackages = result.TotalPackages;

            if (result.FailureCount > 0 && result.SuccessCount == 0)
            {
                UpdateStatus("Update Failed", "✗");
                UpdateSubStatus($"All {result.FailureCount} package(s) failed");
                UpdateCurrentPackage("Update process completed with errors");
                UpdateProgressDetails($"Failed to update packages. Error: {result.ErrorMessage ?? "Unknown error"}");
                SetProgressBar(false, 0);
                UpdatePercentage(0);
            }
            else if (result.SuccessCount == 0 && result.TotalPackages == 0)
            {
                UpdateStatus("System Up to Date", "✓");
                UpdateSubStatus("No updates available");
                UpdateCurrentPackage("All software packages are current");
                UpdateProgressDetails("All software is up to date!");
                SetProgressBar(false, 100);
                UpdatePercentage(100);
                UpdatePackageCounter(0, 0);
            }
            else
            {
                var total = result.SuccessCount + result.FailureCount;
                UpdateStatus("Updates Complete", "✓");
                UpdateSubStatus($"Successfully updated {result.SuccessCount} of {total} package(s)");
                UpdateCurrentPackage($"Process completed in {result.Duration.TotalSeconds:F1} seconds");
                UpdateProgressDetails($"✓ Successfully updated {result.SuccessCount} package(s)" +
                    (result.FailureCount > 0 ? $"\n✗ {result.FailureCount} package(s) failed to update" : "") +
                    $"\n\nTotal duration: {result.Duration.TotalSeconds:F1} seconds");
                SetProgressBar(false, 100);
                UpdatePercentage(100);
                UpdatePackageCounter(result.SuccessCount, total);
            }

            FooterText.Text = "Update process completed successfully";
            FooterSubText.Text = $"Log: {_logger.GetLogFilePath()}";
        }

        private void UpdateStatus(string status, string icon = "⟳")
        {
            StatusText.Text = status;
            StatusIcon.Text = icon;
        }

        private void UpdateSubStatus(string subStatus)
        {
            SubStatusText.Text = subStatus;
        }

        private void UpdateCurrentPackage(string packageInfo)
        {
            CurrentPackageText.Text = packageInfo;
        }

        private void UpdateProgressDetails(string details)
        {
            var timestamp = DateTime.Now.ToString("HH:mm:ss");
            var currentText = ProgressDetails.Text;

            if (currentText == "Initializing update system...")
            {
                ProgressDetails.Text = $"[{timestamp}] {details}";
            }
            else
            {
                ProgressDetails.Text = currentText + Environment.NewLine + $"[{timestamp}] {details}";
            }

            // Auto-scroll to bottom
            ProgressScrollViewer.ScrollToEnd();
        }

        private void SetProgressBar(bool isIndeterminate, double value)
        {
            UpdateProgressBar.IsIndeterminate = isIndeterminate;
            if (!isIndeterminate)
            {
                UpdateProgressBar.Value = value;
            }
        }

        private void UpdatePercentage(double percentage)
        {
            PercentageText.Text = $"{percentage:F0}%";
        }

        private void UpdatePackageCounter(int current, int total)
        {
            _currentPackage = current;
            _totalPackages = total;
            PackageCounter.Text = $"{current}/{total}";
        }

        private void StartIconAnimation()
        {
            if (_rotationAnimation != null)
            {
                IconRotate.BeginAnimation(RotateTransform.AngleProperty, _rotationAnimation);
            }
        }

        private void StopIconAnimation()
        {
            IconRotate.BeginAnimation(RotateTransform.AngleProperty, null);
            IconRotate.Angle = 0;
        }

        private void MainWindow_Closing(object? sender, System.ComponentModel.CancelEventArgs e)
        {
            if (_isUpdating)
            {
                e.Cancel = true;
                return;
            }
        }

    }
}

