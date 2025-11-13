# Build script for XOGENT Winget Auto-Updater
# This script builds both the application and MSI installer
# Copyright © XOGENT, INC 2024

param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

Write-Host "=== XOGENT Winget Auto-Updater Build Script ===" -ForegroundColor Cyan
Write-Host ""

# Check for .NET SDK
Write-Host "Checking for .NET SDK..." -ForegroundColor Yellow
$dotnetPath = $null

# Check common locations
$dotnetPaths = @(
    "C:\Program Files\dotnet\dotnet.exe",
    "C:\Program Files (x86)\dotnet\dotnet.exe",
    "$env:ProgramFiles\dotnet\dotnet.exe",
    "$env:ProgramFiles(x86)\dotnet\dotnet.exe"
)

foreach ($path in $dotnetPaths) {
    if (Test-Path $path) {
        $dotnetPath = $path
        break
    }
}

# Try to find in PATH
if (-not $dotnetPath) {
    try {
        $dotnetCmd = Get-Command dotnet -ErrorAction Stop
        $dotnetPath = $dotnetCmd.Source
    } catch {
        # Not found
    }
}

if (-not $dotnetPath -or -not (Test-Path $dotnetPath)) {
    Write-Host "ERROR: .NET SDK not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install .NET 8.0 SDK from:" -ForegroundColor Yellow
    Write-Host "https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host "Found .NET SDK at: $dotnetPath" -ForegroundColor Green
& $dotnetPath --version
Write-Host ""

# Build the application
Write-Host "Building application..." -ForegroundColor Yellow
$appProject = "WingetUpdater\WingetUpdater.csproj"

if (-not (Test-Path $appProject)) {
    Write-Host "ERROR: Project file not found: $appProject" -ForegroundColor Red
    exit 1
}

& $dotnetPath restore $appProject
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Restore failed!" -ForegroundColor Red
    exit 1
}

& $dotnetPath build $appProject -c $Configuration --no-restore
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Application built successfully!" -ForegroundColor Green
Write-Host ""

# Check for WiX Toolset
Write-Host "Checking for WiX Toolset..." -ForegroundColor Yellow
$wixPath = $null
$candlePath = $null
$lightPath = $null

# Check common WiX locations
$wixPaths = @(
    "C:\Program Files (x86)\WiX Toolset v3.14\bin",
    "C:\Program Files\WiX Toolset v3.14\bin",
    "C:\Program Files (x86)\WiX Toolset v3.11\bin",
    "C:\Program Files\WiX Toolset v3.11\bin",
    "${env:ProgramFiles(x86)}\WiX Toolset v3.14\bin",
    "$env:ProgramFiles\WiX Toolset v3.14\bin",
    "${env:ProgramFiles(x86)}\WiX Toolset v3.11\bin",
    "$env:ProgramFiles\WiX Toolset v3.11\bin"
)

foreach ($wixDir in $wixPaths) {
    $candle = Join-Path $wixDir "candle.exe"
    $light = Join-Path $wixDir "light.exe"
    if ((Test-Path $candle) -and (Test-Path $light)) {
        $candlePath = $candle
        $lightPath = $light
        $wixPath = $wixDir
        break
    }
}

# Try to find in PATH
if (-not $candlePath) {
    try {
        $candleCmd = Get-Command candle -ErrorAction Stop
        $lightCmd = Get-Command light -ErrorAction Stop
        $candlePath = $candleCmd.Source
        $lightPath = $lightCmd.Source
    } catch {
        # Not found
    }
}

if (-not $candlePath -or -not (Test-Path $candlePath)) {
    Write-Host "WARNING: WiX Toolset not found!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "MSI installer cannot be built without WiX Toolset." -ForegroundColor Yellow
    Write-Host "Please install WiX Toolset v3.11+ from:" -ForegroundColor Yellow
    Write-Host "https://wixtoolset.org/releases/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Application build completed successfully." -ForegroundColor Green
    Write-Host "Output: WingetUpdater\bin\$Configuration\net8.0-windows\" -ForegroundColor Cyan
    exit 0
}

Write-Host "Found WiX Toolset at: $wixPath" -ForegroundColor Green
Write-Host ""

# Build the MSI installer
Write-Host "Building MSI installer..." -ForegroundColor Yellow

$installerDir = "Installer"
$wxsFile = Join-Path $installerDir "Product.wxs"
$outputDir = Join-Path $installerDir "bin\$Configuration"
$appOutputDir = "WingetUpdater\bin\$Configuration\net8.0-windows"

if (-not (Test-Path $wxsFile)) {
    Write-Host "ERROR: WiX source file not found: $wxsFile" -ForegroundColor Red
    exit 1
}

# Ensure output directory exists
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Verify application executable exists
$appExePath = Join-Path $appOutputDir "XogentWingetUpdater.exe"
if (-not (Test-Path $appExePath)) {
    Write-Host "ERROR: Application executable not found: $appExePath" -ForegroundColor Red
    Write-Host "Please ensure the application build completed successfully." -ForegroundColor Yellow
    exit 1
}

# Compile WiX source
Write-Host "Compiling WiX source..." -ForegroundColor Yellow
$wixobjFile = Join-Path $outputDir "Product.wixobj"

# Update the source path in the WXS file temporarily for build
$wxsContent = Get-Content $wxsFile -Raw
$relativeAppPath = Resolve-Path $appExePath -Relative
$relativeAppPath = $relativeAppPath -replace '\\', '/'
$tempWxsFile = Join-Path $outputDir "Product.temp.wxs"
$wxsContent = $wxsContent -replace 'Source="\.\.\\WingetUpdater\\bin\\Release\\net8\.0-windows\\XogentWingetUpdater\.exe"', "Source=`"$appExePath`""
Set-Content -Path $tempWxsFile -Value $wxsContent

& $candlePath -out $wixobjFile -ext WixUtilExtension -ext WixUIExtension $tempWxsFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: WiX compilation failed!" -ForegroundColor Red
    Remove-Item $tempWxsFile -ErrorAction SilentlyContinue
    exit 1
}

Remove-Item $tempWxsFile -ErrorAction SilentlyContinue

# Link and create MSI
Write-Host "Linking MSI..." -ForegroundColor Yellow
$msiFile = Join-Path $outputDir "XogentWingetUpdater.msi"

& $lightPath -out $msiFile -ext WixUtilExtension -ext WixUIExtension $wixobjFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: MSI linking failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Application:" -ForegroundColor Cyan
Write-Host "  $appExePath" -ForegroundColor White
Write-Host ""
Write-Host "MSI Installer:" -ForegroundColor Cyan
Write-Host "  $msiFile" -ForegroundColor White
Write-Host ""

