#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.local/bin"
EXECUTABLE="$INSTALL_DIR/nik"

echo "Uninstalling Niksphere..."

if [ -f "$EXECUTABLE" ]; then
    rm -f "$EXECUTABLE"
    echo "Niksphere binary ($EXECUTABLE) has been removed."
else
    echo "Niksphere was not found at $EXECUTABLE. Skipping removal."
fi

echo ""
echo "---> UNINSTALL SUCCESSFUL! <---"
echo "Note: You may need to manually remove '$INSTALL_DIR' from your PATH in your ~/.bashrc, ~/.zshrc or ~/.profile,"
echo "if you no longer need this directory for other executables."
