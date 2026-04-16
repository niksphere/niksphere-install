$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:LOCALAPPDATA "niksphere\bin"
$BaseDir = Join-Path $env:LOCALAPPDATA "niksphere"

Write-Host "Uninstalling Niksphere..."

# 1. Remove files
$ProcessName = "nik"

if (Test-Path $BaseDir) {
    # Isolate directory by renaming it to break automatic process restart loops (e.g., from VS Code)
    $IsolatedDir = "$BaseDir-old_uninstall"
    if (Test-Path $IsolatedDir) { Remove-Item -Path $IsolatedDir -Recurse -Force -ErrorAction SilentlyContinue }
    
    try {
        Rename-Item -Path $BaseDir -NewName "niksphere-old_uninstall" -ErrorAction Stop
        $TargetDir = $IsolatedDir
    } catch {
        $TargetDir = $BaseDir
    }

    if (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
        Write-Host "Stopping running instances of $ProcessName..."
        Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    Remove-Item -Path $TargetDir -Recurse -Force
    Write-Host "Niksphere directory has been removed."
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
