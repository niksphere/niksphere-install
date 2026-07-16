# Niksphere Distribution & Installation Hub

This repository is the central distribution hub for the **Niksphere** ecosystem. It serves two primary purposes:
1. Hosts the static files and installation scripts for **[install.niksphere.de](https://install.niksphere.de)**.
2. Tracks all official and development release artifacts across various update channels inside `releases.json`.

---

## 🛠️ For End-Users:

Niksphere CLI (`nik`) can be installed using one-line scripts. No administrator (root) privileges are required; the CLI installs directly into the user's local directory (`%LOCALAPPDATA%` on Windows, `~/.local/bin` on macOS/Linux).

### Installation & Updates

To install or update the Niksphere CLI:
* **Windows**: `Invoke-RestMethod https://install.niksphere.de/install.ps1 | Invoke-Expression`
* **macOS & Linux**: `curl -fsSL https://install.niksphere.de/install.sh | bash`

### Uninstallation
To completely remove the Niksphere CLI from your system:
* **Windows**: `Invoke-RestMethod https://install.niksphere.de/uninstall.ps1 | Invoke-Expression`
* **macOS & Linux**: `curl -fsSL https://install.niksphere.de/uninstall.sh | bash`

---

## 📦 For Developers: Release Architecture & Manifest

This repository acts as the metadata store for all release components of Niksphere (e.g., `cli`, `engine`, `ide-vscode`).

### The `releases.json` Manifest
The [releases.json](releases.json) file tracks the latest active releases across different update channels (like `stable` and `dev`). 

```json
{
  "channels": {
    "stable": {
      "version": "v1.0.25",
      "published_at": "2026-04-16T14:07:38Z",
      "notes": "...",
      "cli": {
        "win-x64": "https://github.com/niksphere/niksphere-install/releases/download/v1.0.25/niksphere-cli-v1.0.25-win-x64.zip",
        "linux-x64": "..."
      },
      "engine": {
        "docker": "https://github.com/niksphere/niksphere-install/releases/download/v1.0.25/niksphere-engine-v1.0.25-docker.tar"
      },
      "ide-vscode": "https://github.com/niksphere/niksphere-install/releases/download/v1.0.25/niksphere-ide-vscode-v1.0.25.vsix"
    }
  }
}
```

### Automatic Manifest Updates (GitHub Actions)
The repository contains an automated GitHub Actions workflow [update-manifest.yml](.github/workflows/update-manifest.yml) that automatically runs whenever a new release is published:

1. **Trigger**: Runs on `release: [published]` or manually via `workflow_dispatch`.
2. **Asset Parsing**: Scans release assets matching the naming convention:
   `niksphere-{component}-{version}[-{platform}].{ext}`
   * *Components*: e.g., `cli`, `engine`, `ide-vscode`
   * *Platforms*: e.g., `win-x64`, `linux-arm64`, `docker`
3. **Commit**: Dynamically updates `releases.json` and commits it to the `main` branch, making the metadata instantly available at `https://install.niksphere.de/releases.json`.

---

## 📦 Active Releases / Download Portal

<!-- RELEASES_START -->
### 🚀 Stable Channel

| Component | Version | Published At | Download Links |
| --- | --- | --- | --- |
| `engine` | `v1.0.0-build.6` | 2026-07-16 10:25 UTC | [linux-arm64](https://github.com/niksphere/niksphere-install/releases/download/engine/v1.0.0-build.6/niksphere-engine-v1.0.0-build.6-linux-arm64.zip) \| [linux-x64](https://github.com/niksphere/niksphere-install/releases/download/engine/v1.0.0-build.6/niksphere-engine-v1.0.0-build.6-linux-x64.zip) \| [mac-arm64](https://github.com/niksphere/niksphere-install/releases/download/engine/v1.0.0-build.6/niksphere-engine-v1.0.0-build.6-mac-arm64.zip) \| [mac-x64](https://github.com/niksphere/niksphere-install/releases/download/engine/v1.0.0-build.6/niksphere-engine-v1.0.0-build.6-mac-x64.zip) \| [win-arm64](https://github.com/niksphere/niksphere-install/releases/download/engine/v1.0.0-build.6/niksphere-engine-v1.0.0-build.6-win-arm64.zip) \| [win-x64](https://github.com/niksphere/niksphere-install/releases/download/engine/v1.0.0-build.6/niksphere-engine-v1.0.0-build.6-win-x64.zip) |

### 🚀 Insider Channel

| Component | Version | Published At | Download Links |
| --- | --- | --- | --- |
| `ide-vscode` | `v1.0.0-build.2` | 2026-07-16 09:50 UTC | [vsix](https://github.com/niksphere/niksphere-install/releases/download/ide-vscode/v1.0.0-build.2/niksphere-ide-vscode-v1.0.0-build.2.vsix) |

<!-- RELEASES_END -->

---

## 📁 Repository Structure

* **[.github/workflows/](.github/workflows/)**: Contains the automation workflow for updating `releases.json`.
* **[CNAME](CNAME)**: Mapped to `install.niksphere.de` for GitHub Pages.
* **[index.html](index.html)**: Redirects browser traffic to the main website.
* **[install.sh](install.sh) / [install.ps1](install.ps1)**: Script downloads for the Niksphere CLI.
* **[uninstall.sh](uninstall.sh) / [uninstall.ps1](uninstall.ps1)**: Cleanup utilities.
* **`releases.json`**: Auto-generated release catalog (live at `https://install.niksphere.de/releases.json`).
