param (
    [string]$Channel = "stable",
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

$ManifestUrl = "https://install.niksphere.de/releases.json"
$FallbackUrl = "https://raw.githubusercontent.com/niksphere/niksphere-install/main/releases.json"

Write-Host "Fetching release information for Niksphere CLI..."
try {
    $Manifest = Invoke-RestMethod -Uri $ManifestUrl -UseBasicParsing
} catch {
    try {
        $Manifest = Invoke-RestMethod -Uri $FallbackUrl -UseBasicParsing
    } catch {
        Write-Error "Failed to fetch release manifest. Check your internet connection."
        exit 1
    }
}

$Arch = "x64"
if ($env:PROCESSOR_ARCHITECTURE -match "ARM") {
    $Arch = "arm64"
}

$Platform = "win-$Arch"

$ComponentReleases = $Manifest.channels.$Channel.cli
if (-not $ComponentReleases -or $ComponentReleases.Count -eq 0) {
    Write-Error "No releases found for CLI in channel '$Channel'."
    exit 1
}

if ($Version) {
    $SelectedRelease = $ComponentReleases | Where-Object { $_.version -eq $Version } | Select-Object -First 1
    if (-not $SelectedRelease) {
        Write-Error "Release version '$Version' not found for CLI in channel '$Channel'."
        exit 1
    }
} else {
    $SelectedRelease = $ComponentReleases[0]
}

$DownloadUrl = $SelectedRelease.assets.$Platform

if (-not $DownloadUrl) {
    Write-Error "No matching asset found for Windows $Arch in CLI $($SelectedRelease.version) ($Channel channel)."
    exit 1
}

$ZipPath = Join-Path $env:TEMP "niksphere-cli.zip"
$InstallDir = Join-Path $env:LOCALAPPDATA "niksphere\bin"

Write-Host "Downloading Niksphere CLI $($SelectedRelease.version) ($Platform)..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing

Write-Host "Extracting to $InstallDir..."
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
Remove-Item $ZipPath

# The executable is natively named 'nik.exe' in the zip, so no renaming is necessary.

# Add path to system environment variables if it doesn't exist yet
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notmatch [regex]::Escape($InstallDir)) {
    Write-Host "Adding $InstallDir to User PATH..."
    [Environment]::SetEnvironmentVariable("PATH", "$UserPath;$InstallDir", "User")
}

# Add path to the current session's environment variable so it can be used immediately
if ($env:Path -notmatch [regex]::Escape($InstallDir)) {
    $env:Path += ";$InstallDir"
}

if ($UserPath -notmatch [regex]::Escape($InstallDir)) {
    Write-Host "`n---> INSTALLATION SUCCESSFUL! The 'nik' command is ready to use in this session! For other sessions, please restart your terminal. <---"
} else {
    Write-Host "`n---> UPDATE SUCCESSFUL! Niksphere CLI has been updated and is ready to use! <---"
}
