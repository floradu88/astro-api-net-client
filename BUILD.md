# Build Instructions

This project supports building as a DLL and generating NuGet packages using PowerShell scripts.

## Prerequisites

- .NET SDK 7.0 or later
- PowerShell 5.1 or later

## Quick Start

To build both the DLL and NuGet package in one command:

```powershell
.\Build-All.ps1
```

This will:
1. Build the DLL in Release configuration
2. Generate the NuGet package
3. Display build summary with file locations

## Build Scripts

### 1. Build DLL Only

Builds the AstroAPIClient as a DLL library:

```powershell
.\Build-DLL.ps1
```

**Options:**
- `-Configuration`: Build configuration (Debug or Release). Default: Release
- `-Clean`: Clean previous builds before building. Default: true

**Examples:**
```powershell
# Build in Debug mode
.\Build-DLL.ps1 -Configuration Debug

# Build without cleaning
.\Build-DLL.ps1 -Clean:$false
```

**Output:**
- DLL: `.\bin\{Configuration}\net7.0\AstroAPIClient.dll`
- XML Documentation: `.\bin\{Configuration}\net7.0\AstroAPIClient.xml`
- PDB Symbols: `.\bin\{Configuration}\net7.0\AstroAPIClient.pdb`

### 2. Generate NuGet Package Only

Generates a NuGet package from the project:

```powershell
.\Build-NuGet.ps1
```

**Options:**
- `-Configuration`: Build configuration (Debug or Release). Default: Release
- `-OutputPath`: NuGet package output directory. Default: .\NuGet
- `-Version`: Override package version (e.g., "1.0.1"). Default: Uses version from .csproj
- `-NoBuild`: Skip building the project (assumes it's already built). Default: false

**Examples:**
```powershell
# Generate package with custom version
.\Build-NuGet.ps1 -Version "1.0.1"

# Generate package to custom directory
.\Build-NuGet.ps1 -OutputPath ".\Packages"

# Generate package without rebuilding (faster if DLL already exists)
.\Build-NuGet.ps1 -NoBuild
```

**Output:**
- NuGet Package: `.\NuGet\AstroAPIClient.{Version}.nupkg`
- Symbol Package: `.\NuGet\AstroAPIClient.{Version}.snupkg` (if symbols enabled)

### 3. Build Both DLL and NuGet Package

Builds the DLL and generates the NuGet package in one command:

```powershell
.\Build-All.ps1
```

**Options:**
- `-Configuration`: Build configuration (Debug or Release). Default: Release
- `-NuGetOutputPath`: NuGet package output directory. Default: .\NuGet
- `-Version`: Override package version. Default: Uses version from .csproj
- `-SkipDLL`: Skip DLL build step. Default: false
- `-SkipNuGet`: Skip NuGet package generation. Default: false

**Examples:**
```powershell
# Build everything in Release mode with custom version
.\Build-All.ps1 -Version "1.0.1"

# Build in Debug mode
.\Build-All.ps1 -Configuration Debug

# Build only NuGet package (skip DLL build)
.\Build-All.ps1 -SkipDLL
```

## Output Locations

- **DLL**: `.\bin\{Configuration}\net7.0\AstroAPIClient.dll`
- **XML Documentation**: `.\bin\{Configuration}\net7.0\AstroAPIClient.xml`
- **PDB Symbols**: `.\bin\{Configuration}\net7.0\AstroAPIClient.pdb`
- **NuGet Package**: `.\NuGet\AstroAPIClient.{Version}.nupkg`
- **Symbol Package**: `.\NuGet\AstroAPIClient.{Version}.snupkg`

## Using the NuGet Package Locally

After generating the NuGet package, you can use it in other projects:

### Method 1: Add as Local NuGet Source

1. Add the NuGet source:
```powershell
dotnet nuget add source ".\NuGet" --name LocalAstroAPI
```

2. Install the package in your project:
```powershell
dotnet add package AstroAPIClient --source LocalAstroAPI
```

### Method 2: Direct Package Reference

Add it directly in your `.csproj`:
```xml
<ItemGroup>
  <PackageReference Include="AstroAPIClient" Version="1.0.0" />
</ItemGroup>
```

Then restore packages:
```powershell
dotnet restore --source ".\NuGet"
```

### Method 3: Direct Path Reference

Add directly to your `.csproj`:
```xml
<ItemGroup>
  <PackageReference Include="AstroAPIClient" Version="1.0.0">
    <Source>D:\code\projects\astro-api-net-client\NuGet</Source>
  </PackageReference>
</ItemGroup>
```

## Project Configuration

The project is configured in `AstroAPIClient.csproj`:
- **Output Type**: Library (DLL)
- **Target Framework**: .NET 7.0
- **Package ID**: AstroAPIClient
- **Current Version**: 1.0.0
- **Documentation**: XML documentation is generated automatically
- **Symbols**: Symbol packages (.snupkg) are generated for debugging

### Updating Package Version

You can update the package version in two ways:

1. **Edit the .csproj file:**
   ```xml
   <Version>1.0.1</Version>
   ```

2. **Use the -Version parameter:**
   ```powershell
   .\Build-NuGet.ps1 -Version "1.0.1"
   .\Build-All.ps1 -Version "1.0.1"
   ```

## Features

- ✅ Automatic DLL generation with XML documentation
- ✅ NuGet package generation with symbol packages
- ✅ Support for Debug and Release configurations
- ✅ Version override capability
- ✅ Comprehensive error handling
- ✅ Build time tracking
- ✅ Detailed output with file locations and sizes

## Troubleshooting

### Build Fails with "Project file not found"
- Ensure you're running the script from the project root directory
- Verify that `AstroAPIClient.csproj` exists in the current directory

### NuGet Package Not Found After Build
- Check that the build completed successfully
- Verify the output directory exists and is accessible
- Look for any error messages in the build output

### DLL Not Found After Build
- Check the `.\bin\{Configuration}\net7.0\` directory
- Verify the build completed without errors
- Try cleaning and rebuilding: `.\Build-DLL.ps1 -Configuration Release`

