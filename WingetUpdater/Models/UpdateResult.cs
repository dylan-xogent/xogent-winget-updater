using System;
using System.Collections.Generic;

namespace XogentWingetUpdater.Models
{
    public class UpdateResult
    {
        public int TotalPackages { get; set; }
        public int SuccessCount { get; set; }
        public int FailureCount { get; set; }
        public List<string> UpdatedPackages { get; set; } = new List<string>();
        public List<string> FailedPackages { get; set; } = new List<string>();
        public TimeSpan Duration { get; set; }
        public bool WingetAvailable { get; set; } = true;
        public string? ErrorMessage { get; set; }
    }
}

