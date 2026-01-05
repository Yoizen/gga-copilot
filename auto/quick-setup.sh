#!/bin/bash
# Quick setup - One command installation
# Usage: curl -sSL https://tu-url/quick-setup.sh | bash
#    or: ./quick-setup.sh

set -e

REPO_URL="https://github.com/github/gga-copilot.git"
$INSTALL_DIR="/tmp/gga-bootstrap-$$"

echo "🚀 GGA Quick Setup"
echo ""

cleanup() {
    rm -rf "$INSTALL_DIR" 2>/dev/null || true
}

trap cleanup EXIT

# Clone repo to temp
echo "Downloading bootstrap scripts..."
git clone --quiet "$REPO_URL" "$INSTALL_DIR" 2>/dev/null

if [ ! -f "$INSTALL_DIR/auto/bootstrap.sh" ]; then
    echo "✗ Failed to download bootstrap script"
    exit 1
fi

# Run bootstrap
echo "Running setup..."
bash "$INSTALL_DIR/auto/bootstrap.sh" "$@"

echo ""
echo "✓ Setup complete!"
