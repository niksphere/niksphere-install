$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:LOCALAPPDATA "niksphere\bin"
$BaseDir = Join-Path $env:LOCALAPPDATA "niksphere"

Write-Host "Uninstalling Niksphere..."

# 1. Remove files
if (Test-Path $BaseDir) {
    Remove-Item -Path $BaseDir -Recurse -Force
    Write-Host "Niksphere directory at $BaseDir has been removed."
} else {
    Write-Host "Niksphere files ($BaseDir) were not found."
}

# 2. Remove from PATH
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath) {
    $PathArray = $UserPath -split ';' | Where-Object { $_ -ne $InstallDir -and $_ -notmatch '^\s*$' }
    $NewPath = $PathArray -join ';'
    
    if ($UserPath -ne $NewPath) {
        [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
        Write-Host "Removed directory from User PATH environment variable ($InstallDir)."
    } else {
        Write-Host "Directory was not present in the PATH environment variable."
    }
}

Write-Host "`n---> UNINSTALL SUCCESSFUL! <---"
Write-Host "Please restart your terminal for the PATH changes to take effect."
