# PowerShell script to build both DLL and NuGet package for AstroAPIClient
# Usage: .\Build-All.ps1 [-Configuration Debug|Release] [-NuGetOutputPath <path>] [-Version <version>] [-SkipDLL] [-SkipNuGet]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$NuGetOutputPath = ".\NuGet",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDLL = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipNuGet = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Building AstroAPIClient - Complete Build" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
if ($Version) {
    Write-Host "Version Override: $Version" -ForegroundColor Yellow
}
Write-Host ""

$startTime = Get-Date
$buildSuccess = $true
$dllBuilt = $false
$nugetBuilt = $false

try {
    # Step 1: Build DLL
    if (-not $SkipDLL) {
        Write-Host "Step 1: Building DLL..." -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        
        $dllScript = Join-Path $PSScriptRoot "Build-DLL.ps1"
        if (-not (Test-Path $dllScript)) {
            $dllScript = ".\Build-DLL.ps1"
        }
        
        & $dllScript -Configuration $Configuration -Clean
        
        if ($LASTEXITCODE -ne 0) {
            throw "DLL build failed with exit code $LASTEXITCODE"
        }
        
        $dllBuilt = $true
        Write-Host ""
    } else {
        Write-Host "Step 1: Skipping DLL build (SkipDLL flag set)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Step 2: Generate NuGet Package
    if (-not $SkipNuGet) {
        Write-Host "Step 2: Generating NuGet Package..." -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        
        $nugetScript = Join-Path $PSScriptRoot "Build-NuGet.ps1"
        if (-not (Test-Path $nugetScript)) {
            $nugetScript = ".\Build-NuGet.ps1"
        }
        
        # Step 2: Generate NuGet Package
        $nugetParams = @{
            Configuration = $Configuration
            OutputPath = $NuGetOutputPath
            NoBuild = $true  # Don't rebuild, DLL was already built
        }
        
        if ($Version) {
            $nugetParams["Version"] = $Version
        }
        
        & $nugetScript @nugetParams
        
        if ($LASTEXITCODE -ne 0) {
            throw "NuGet package generation failed with exit code $LASTEXITCODE"
        }
        
        $nugetBuilt = $true
        Write-Host ""
    } else {
        Write-Host "Step 2: Skipping NuGet package generation (SkipNuGet flag set)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Calculate build time
    $endTime = Get-Date
    $buildDuration = $endTime - $startTime
    
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Build Complete - All Tasks Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Yellow
    if ($dllBuilt) {
        Write-Host "  [OK] DLL built successfully" -ForegroundColor Green
    }
    if ($nugetBuilt) {
        Write-Host "  [OK] NuGet package generated successfully" -ForegroundColor Green
    }
    Write-Host "  Build Duration: $($buildDuration.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Gray
    Write-Host ""
    
    # Display file locations
    $dllPath = ".\bin\$Configuration\net7.0\AstroAPIClient.dll"
    if (-not (Test-Path $dllPath)) {
        $dllPath = ".\Bin\$Configuration\net7.0\AstroAPIClient.dll"
    }
    
    if ($dllBuilt -and (Test-Path $dllPath)) {
        $dllInfo = Get-Item $dllPath
        Write-Host "DLL Location: $($dllInfo.FullName)" -ForegroundColor Cyan
        Write-Host "  Size: $([math]::Round($dllInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
    }
    
    if ($nugetBuilt) {
        $nupkgFiles = Get-ChildItem -Path $NuGetOutputPath -Filter "*.nupkg" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
        if ($nupkgFiles.Count -gt 0) {
            $pkgInfo = Get-Item $nupkgFiles[0].FullName
            Write-Host "NuGet Package: $($pkgInfo.FullName)" -ForegroundColor Cyan
            Write-Host "  Size: $([math]::Round($pkgInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
        }
    }
    Write-Host ""
    
} catch {
    $buildSuccess = $false
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Build Failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ScriptStackTrace) {
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
    }
    Write-Host ""
    exit 1
}

if ($buildSuccess) {
    exit 0
} else {
    exit 1
}

