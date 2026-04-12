# Niksphere CLI

Welcome to the official installation repository for the **Niksphere CLI**. 

This repository provides seamless, one-line installation scripts to securely download and configure the latest Niksphere binaries onto your system. It supports Windows (amd64/arm64) as well as macOS and Linux.

## Installation

> **Note:** Administrator (root) privileges are **not** required. The CLI installs directly into your user's local directory (`%LOCALAPPDATA%` on Windows, `~/.local/bin` on Mac/Linux).

### Windows (PowerShell)

Open your PowerShell terminal and execute the following script:

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/niksphere/niksphere-install/main/install.ps1 | Invoke-Expression
```

### macOS & Linux (Bash)

Open your terminal and run the following shell command:

```bash
curl -fsSL https://raw.githubusercontent.com/niksphere/niksphere-install/main/install.sh | bash
```

## Post-Installation

Once the installation successfully completes, you will need to **restart your terminal** or open a new tab so that the newly added system paths can be refreshed.

After restarting, verify your installation by simply typing:

```bash
nik --version
```

## Uninstallation

If you wish to remove Niksphere from your system, you can use the provided standalone uninstall scripts.

### Windows (PowerShell)

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/niksphere/niksphere-install/main/uninstall.ps1 | Invoke-Expression
```

### macOS & Linux (Bash)

```bash
curl -fsSL https://raw.githubusercontent.com/niksphere/niksphere-install/main/uninstall.sh | bash
```

---
*For manual installations or exploring specific version archives, see the [Releases page](../../releases) of this repository.*
