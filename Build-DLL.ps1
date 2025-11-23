# PowerShell script to build the AstroAPIClient DLL
# Usage: .\Build-DLL.ps1 [-Configuration Debug|Release] [-OutputPath <path>] [-Clean]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean = $true
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building AstroAPIClient DLL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host ""

# Get the project file
$projectFile = Resolve-Path ".\AstroAPIClient.csproj" -ErrorAction SilentlyContinue
if (-not $projectFile) {
    Write-Host "Error: Project file not found: AstroAPIClient.csproj" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor Red
    exit 1
}

Write-Host "Project File: $projectFile" -ForegroundColor Gray
Write-Host ""

# Check if .NET SDK is available
try {
    $dotnetVersion = dotnet --version
    Write-Host "Using .NET SDK: $dotnetVersion" -ForegroundColor Gray
} catch {
    Write-Host "Error: .NET SDK not found. Please install .NET SDK 7.0 or later." -ForegroundColor Red
    exit 1
}

# Clean previous builds if requested
if ($Clean) {
    Write-Host "Cleaning previous builds..." -ForegroundColor Green
    dotnet clean $projectFile --configuration $Configuration | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Clean operation had issues, continuing anyway..." -ForegroundColor Yellow
    }
    Write-Host ""
}

# Build the project
Write-Host "Building project..." -ForegroundColor Green
$buildOutput = dotnet build $projectFile --configuration $Configuration --no-incremental 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed!" -ForegroundColor Red
    Write-Host $buildOutput -ForegroundColor Red
    exit 1
}

# Find the DLL - check standard output location
$dllPath = ".\bin\$Configuration\net7.0\AstroAPIClient.dll"
if (-not (Test-Path $dllPath)) {
    # Try alternative location
    $dllPath = ".\Bin\$Configuration\net7.0\AstroAPIClient.dll"
}

if (Test-Path $dllPath) {
    $dllInfo = Get-Item $dllPath
    $xmlPath = $dllPath -replace '\.dll$', '.xml'
    $pdbPath = $dllPath -replace '\.dll$', '.pdb'
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Build Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "DLL Location: $($dllInfo.FullName)" -ForegroundColor Cyan
    Write-Host "File Size: $([math]::Round($dllInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
    Write-Host "Last Modified: $($dllInfo.LastWriteTime)" -ForegroundColor Cyan
    
    if (Test-Path $xmlPath) {
        Write-Host "XML Documentation: $(Resolve-Path $xmlPath)" -ForegroundColor Gray
    }
    if (Test-Path $pdbPath) {
        Write-Host "PDB Symbols: $(Resolve-Path $pdbPath)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Build artifacts are ready for distribution." -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Error: DLL not found at expected location: $dllPath" -ForegroundColor Red
    Write-Host "Checking build output..." -ForegroundColor Yellow
    Get-ChildItem -Path ".\bin" -Recurse -Filter "*.dll" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Found DLL: $($_.FullName)" -ForegroundColor Yellow
    }
    exit 1
}

