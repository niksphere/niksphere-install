#!/usr/bin/env bash
set -e

CHANNEL="stable"
VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--channel)
            CHANNEL="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

REPO="niksphere/niksphere-install"

echo "Fetching release information for Niksphere..."
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
    DOWNLOAD_URL=$(echo "$MANIFEST_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
releases = data.get('channels', {}).get('$CHANNEL', {}).get('cli', [])
version_target = '$VERSION'
selected = None
if version_target:
    for r in releases:
        if r.get('version') == version_target:
            selected = r
            break
else:
    selected = releases[0] if releases else None

if selected:
    print(selected.get('assets', {}).get('${OS_SHORT}-${ARCH_SHORT}', ''))
" 2>/dev/null)
fi

if [ -z "$DOWNLOAD_URL" ]; then
    if [ -n "$VERSION" ]; then
        DOWNLOAD_URL=$(echo "$MANIFEST_JSON" | grep -o 'https://github.com/niksphere/niksphere-install/releases/download/[^"]*' | grep "cli" | grep "$VERSION" | grep "${OS_SHORT}-${ARCH_SHORT}" | head -n 1)
    else
        DOWNLOAD_URL=$(echo "$MANIFEST_JSON" | grep -o 'https://github.com/niksphere/niksphere-install/releases/download/[^"]*' | grep "cli" | grep "${OS_SHORT}-${ARCH_SHORT}" | head -n 1)
    fi
fi

if [ -z "$DOWNLOAD_URL" ]; then
    if [ -n "$VERSION" ]; then
        echo "Error: Release version '$VERSION' not found for $OS_SHORT $ARCH_SHORT in $CHANNEL channel."
    else
        echo "Error: No matching release found for $OS_SHORT $ARCH_SHORT in $CHANNEL channel."
    fi
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
