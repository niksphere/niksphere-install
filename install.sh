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

MANIFEST_URL="https://install.niksphere.de/releases.json"
FALLBACK_URL="https://raw.githubusercontent.com/niksphere/niksphere-install/main/releases.json"
CHANNEL="${NIKSPHERE_CHANNEL:-${NIKSPHERE_RELEASE:-${CHANNEL:-stable}}}"

MANIFEST_JSON=$(curl -sL "$MANIFEST_URL")
if [ -z "$MANIFEST_JSON" ] || ! echo "$MANIFEST_JSON" | grep -q "channels"; then
    MANIFEST_JSON=$(curl -sL "$FALLBACK_URL")
fi

if [ -z "$MANIFEST_JSON" ]; then
    echo "Error: Failed to fetch release manifest."
    exit 1
fi

# Try extracting via python3 if available, otherwise fallback to grep
if command -v python3 >/dev/null 2>&1; then
    DOWNLOAD_URL=$(echo "$MANIFEST_JSON" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('channels', {}).get('$CHANNEL', {}).get('cli', {}).get('assets', {}).get('${OS_SHORT}-${ARCH_SHORT}', ''))" 2>/dev/null)
fi

if [ -z "$DOWNLOAD_URL" ]; then
    DOWNLOAD_URL=$(echo "$MANIFEST_JSON" | grep -o 'https://github.com/niksphere/niksphere-install/releases/download/[^"]*' | grep "cli-" | grep "${OS_SHORT}-${ARCH_SHORT}" | head -n 1)
fi

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: No matching release found for $OS_SHORT $ARCH_SHORT in $CHANNEL channel."
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
