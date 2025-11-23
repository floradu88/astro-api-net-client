# PowerShell script to generate NuGet package for AstroAPIClient
# Usage: .\Build-NuGet.ps1 [-Configuration Debug|Release] [-OutputPath <path>] [-Version <version>] [-NoBuild]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\NuGet",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$NoBuild = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Generating NuGet Package" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Output Path: $OutputPath" -ForegroundColor Yellow
if ($Version) {
    Write-Host "Version Override: $Version" -ForegroundColor Yellow
}
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

# Ensure output directory exists
if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $outputDir = $OutputPath
} else {
    $outputDir = Join-Path $PSScriptRoot $OutputPath
}

if (-not (Test-Path $outputDir)) {
    Write-Host "Creating output directory: $outputDir" -ForegroundColor Green
    $outputDir = New-Item -ItemType Directory -Path $outputDir -Force
} else {
    $outputDir = Get-Item $outputDir
    Write-Host "Output directory: $($outputDir.FullName)" -ForegroundColor Gray
}
Write-Host ""

# Build the project first (required for packing) unless NoBuild is specified
if (-not $NoBuild) {
    Write-Host "Building project..." -ForegroundColor Green
    $buildOutput = dotnet build $projectFile --configuration $Configuration --no-incremental 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Build failed!" -ForegroundColor Red
        Write-Host $buildOutput -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# Prepare pack command
$packArgs = @(
    "pack",
    $projectFile.FullName,
    "--configuration", $Configuration,
    "--output", $outputDir.FullName
)

if ($NoBuild) {
    $packArgs += "--no-build"
} else {
    $packArgs += "--no-build"  # Use --no-build since we already built
}

# Add version override if specified
if ($Version) {
    $packArgs += "-p:Version=$Version"
    Write-Host "Using version override: $Version" -ForegroundColor Yellow
}

# Generate the NuGet package
Write-Host "Generating NuGet package..." -ForegroundColor Green
$packOutput = & dotnet $packArgs 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: NuGet package generation failed!" -ForegroundColor Red
    Write-Host $packOutput -ForegroundColor Red
    exit 1
}

# Find the generated .nupkg file
$nupkgFiles = Get-ChildItem -Path $outputDir.FullName -Filter "*.nupkg" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

if ($nupkgFiles.Count -gt 0) {
    $latestPackage = $nupkgFiles[0]
    $snupkgFiles = Get-ChildItem -Path $outputDir.FullName -Filter "*.snupkg" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "NuGet Package Generated Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Package Location: $($latestPackage.FullName)" -ForegroundColor Cyan
    Write-Host "File Size: $([math]::Round($latestPackage.Length / 1KB, 2)) KB" -ForegroundColor Cyan
    Write-Host "Last Modified: $($latestPackage.LastWriteTime)" -ForegroundColor Cyan
    
    if ($snupkgFiles.Count -gt 0) {
        Write-Host "Symbol Package: $($snupkgFiles[0].FullName)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Usage Instructions:" -ForegroundColor Yellow
    Write-Host "  To add as a local source:" -ForegroundColor White
    Write-Host "    dotnet nuget add source `"$($outputDir.FullName)`" --name LocalAstroAPI" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  To install in a project:" -ForegroundColor White
    Write-Host "    dotnet add package AstroAPIClient --source `"$($outputDir.FullName)`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Or add to .csproj:" -ForegroundColor White
    Write-Host "    <PackageReference Include=`"AstroAPIClient`" Version=`"$($latestPackage.BaseName -replace '.*\.(\d+\.\d+\.\d+)', '$1')`" />" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "Error: NuGet package not found in output directory: $($outputDir.FullName)" -ForegroundColor Red
    Write-Host "Checking for any generated files..." -ForegroundColor Yellow
    Get-ChildItem -Path $outputDir.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Found: $($_.Name)" -ForegroundColor Yellow
    }
    exit 1
}

