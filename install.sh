#!/usr/bin/env bash
set -e

REPO="niksphere/niksphere-install"

echo "Fetching latest release information for Niksphere..."
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

if [ "$OS" = "darwin" ]; then
    OS_SHORT="mac"
else
    OS_SHORT="linux"
fi

if [ "$ARCH" = "x86_64" ]; then
    ARCH_SHORT="x64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH_SHORT="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

API_URL="https://api.github.com/repos/$REPO/releases/latest"

# Get the download URL directly from the GitHub API response
DOWNLOAD_URL=$(curl -s $API_URL | grep "browser_download_url.*niksphere-cli-.*-${OS_SHORT}-${ARCH_SHORT}\.zip" | cut -d '"' -f 4 | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: No matching release found for $OS_SHORT $ARCH_SHORT."
    exit 1
fi

echo "Downloading from $DOWNLOAD_URL..."
TMP_ZIP="/tmp/niksphere-cli.zip"
curl -sL "$DOWNLOAD_URL" -o "$TMP_ZIP"

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "Extracting to $INSTALL_DIR..."
# Force overwrite (-o) and quiet mode (-q)
unzip -q -o "$TMP_ZIP" -d "$INSTALL_DIR"
rm "$TMP_ZIP"

# The executable is natively named 'nik' in the zip, ensure it is executable
if [ -f "$INSTALL_DIR/nik" ]; then
    chmod +x "$INSTALL_DIR/nik"
fi

echo ""
echo "---> SUCCESS! Niksphere was successfully installed. <---"
echo "Make sure $INSTALL_DIR is in your PATH. You may need to add this to your ~/.bashrc or ~/.zshrc:"
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo ""
