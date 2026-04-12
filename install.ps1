$ErrorActionPreference = "Stop"

$Repo = "niksphere/niksphere-install"
$ApiUrl = "https://api.github.com/repos/$Repo/releases/latest"

Write-Host "Fetching latest release information for Niksphere..."
try {
    $Release = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing
} catch {
    Write-Error "Failed to fetch release information. Make sure the repository is public and has at least one published release."
    exit 1
}

$Arch = "x64"
if ($env:PROCESSOR_ARCHITECTURE -match "ARM") {
    $Arch = "arm64"
}

# Find the correct zip among the release assets
$AssetNamePattern = "niksphere-cli-.*-win-$Arch\.zip"
$Asset = $Release.assets | Where-Object { $_.name -match $AssetNamePattern } | Select-Object -First 1

if (!$Asset) {
    Write-Error "No matching release found for Windows $Arch in the latest Release."
    exit 1
}

$DownloadUrl = $Asset.browser_download_url
$ZipPath = Join-Path $env:TEMP "niksphere-cli.zip"
$InstallDir = Join-Path $env:LOCALAPPDATA "niksphere\bin"

Write-Host "Downloading $($Asset.name)..."
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
    Write-Host "`n---> INSTALLATION SUCCESSFUL! Please restart your terminal to start using the 'nik' command! <---"
} else {
    Write-Host "`n---> UPDATE SUCCESSFUL! Niksphere CLI has been updated. <---"
}
