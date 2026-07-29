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

$AssetVal = $SelectedRelease.assets.$Platform
if ($AssetVal -is [string]) {
    $DownloadUrl = $AssetVal
} elseif ($AssetVal -and $AssetVal.url) {
    $DownloadUrl = $AssetVal.url
} else {
    $DownloadUrl = $null
}

if (-not $DownloadUrl) {
    Write-Error "No matching asset found for Windows $Arch in CLI $($SelectedRelease.version) ($Channel channel)."
    exit 1
}

$ZipPath = Join-Path $env:TEMP "niksphere-cli.zip"
$BaseDir = Join-Path $env:LOCALAPPDATA "niksphere"
$InstallDir = Join-Path $BaseDir "bin"

Write-Host "Downloading Niksphere CLI $($SelectedRelease.version) ($Platform)..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing

# Stop any running nik.exe processes to release binary lock (e.g. LSP server in VS Code)
$CurrentPid = $PID
Get-Process -Name "nik" -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $CurrentPid } | Stop-Process -Force -ErrorAction SilentlyContinue

# Safe rename fallback if process couldn't be stopped or file is still locked
$TargetExe = Join-Path $InstallDir "nik.exe"
$OldExe = Join-Path $InstallDir "nik.exe.old"
if (Test-Path $TargetExe) {
    Remove-Item $OldExe -Force -ErrorAction SilentlyContinue
    Rename-Item -Path $TargetExe -NewName "nik.exe.old" -Force -ErrorAction SilentlyContinue
}

$Extracted = $false
for ($i = 0; $i -lt 5; $i++) {
    try {
        Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
        $Extracted = $true
        break
    } catch {
        Start-Sleep -Milliseconds 500
    }
}

if (-not $Extracted) {
    Write-Error "Failed to extract Niksphere CLI to $InstallDir. Please ensure no process is locking nik.exe."
    Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
    exit 1
}

Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
Remove-Item $OldExe -Force -ErrorAction SilentlyContinue

# Save uninstall script locally for Windows Settings integration
$LocalUninstallScript = Join-Path $BaseDir "uninstall.ps1"
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "uninstall.ps1"))) {
    Copy-Item -Path (Join-Path $PSScriptRoot "uninstall.ps1") -Destination $LocalUninstallScript -Force
} else {
    $UninstallUrl = "https://install.niksphere.de/uninstall.ps1"
    $UninstallFallbackUrl = "https://raw.githubusercontent.com/niksphere/niksphere-install/main/uninstall.ps1"
    try {
        Invoke-WebRequest -Uri $UninstallUrl -OutFile $LocalUninstallScript -UseBasicParsing
    } catch {
        try {
            Invoke-WebRequest -Uri $UninstallFallbackUrl -OutFile $LocalUninstallScript -UseBasicParsing
        } catch {
            Write-Warning "Could not download uninstall.ps1 for offline uninstallation registration."
        }
    }
}

# Register in Windows Apps & Features (Registry)
try {
    $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Niksphere CLI"
    if (!(Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }

    Set-ItemProperty -Path $RegPath -Name "DisplayName" -Value "Niksphere CLI"
    Set-ItemProperty -Path $RegPath -Name "DisplayVersion" -Value $SelectedRelease.version
    Set-ItemProperty -Path $RegPath -Name "Publisher" -Value "Niksphere"
    Set-ItemProperty -Path $RegPath -Name "DisplayIcon" -Value "$((Join-Path $InstallDir 'nik.exe')),0"
    Set-ItemProperty -Path $RegPath -Name "InstallLocation" -Value $InstallDir
    Set-ItemProperty -Path $RegPath -Name "UninstallString" -Value "powershell.exe -ExecutionPolicy Bypass -NoProfile -File `"$LocalUninstallScript`""
    Set-ItemProperty -Path $RegPath -Name "QuietUninstallString" -Value "powershell.exe -ExecutionPolicy Bypass -NoProfile -File `"$LocalUninstallScript`""
    Set-ItemProperty -Path $RegPath -Name "NoModify" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPath -Name "NoRepair" -Value 1 -Type DWord
} catch {
    Write-Warning "Failed to register Niksphere CLI in Windows Registry: $_"
}

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

