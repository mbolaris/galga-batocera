#!/bin/bash
#
# Install/Update Anki Deck Viewer from GitHub
#
# This script clones or updates the Anki viewer from https://github.com/mbolaris/anki
# and deploys it to /userdata/roms/anki on Batocera
#
# Usage:
#   ./install-from-github.sh        # Install or update
#   ./install-from-github.sh clean  # Clean install (removes existing)
#

set -e

ANKI_REPO="https://github.com/mbolaris/anki.git"
INSTALL_DIR="/userdata/roms/anki"
TEMP_DIR="/tmp/anki-installer"
BACKUP_DIR="/userdata/roms/anki-backup"

echo "========================================"
echo "  Anki Viewer - GitHub Installer"
echo "========================================"
echo ""
echo "Source: $ANKI_REPO"
echo "Target: $INSTALL_DIR"
echo ""

# Check if clean install requested
CLEAN_INSTALL=false
if [ "$1" = "clean" ]; then
    CLEAN_INSTALL=true
    echo "⚠️  Clean install requested - will backup existing installation"
    echo ""
fi

# Create backup if files exist
if [ -d "$INSTALL_DIR/anki_viewer" ] && [ "$CLEAN_INSTALL" = false ]; then
    echo "[1/6] Existing installation found - creating backup..."
    BACKUP_NAME="anki-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$INSTALL_DIR" \
        anki_viewer app.py requirements.txt 2>/dev/null || true
    echo "      ✓ Backup saved to $BACKUP_DIR/$BACKUP_NAME.tar.gz"
elif [ "$CLEAN_INSTALL" = true ] && [ -d "$INSTALL_DIR/anki_viewer" ]; then
    echo "[1/6] Clean install - removing old version..."
    rm -rf "$INSTALL_DIR/anki_viewer" "$INSTALL_DIR/app.py" 2>/dev/null || true
    echo "      ✓ Old version removed"
else
    echo "[1/6] No existing installation found"
fi

# Clean and create temp directory
echo "[2/6] Preparing temporary directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
echo "      ✓ Using $TEMP_DIR"

# Download the repository (Batocera doesn't have git)
echo "[3/6] Downloading Anki viewer from GitHub..."
cd "$TEMP_DIR"

# Download as zip archive from GitHub
GITHUB_ZIP="https://github.com/mbolaris/anki/archive/refs/heads/main.zip"
wget -q "$GITHUB_ZIP" -O anki-main.zip || curl -sL "$GITHUB_ZIP" -o anki-main.zip

if [ ! -f "anki-main.zip" ]; then
    echo "      ✗ Failed to download from GitHub"
    exit 1
fi

# Extract the zip file
unzip -q anki-main.zip
mv anki-main anki-source
rm anki-main.zip

echo "      ✓ Repository downloaded and extracted"

# Copy necessary files to install directory
echo "[4/6] Installing files..."
cd "$TEMP_DIR/anki-source"

# Copy main application files
cp -r anki_viewer "$INSTALL_DIR/"
cp app.py "$INSTALL_DIR/"
cp requirements.txt "$INSTALL_DIR/"

# Copy documentation
cp README.md "$INSTALL_DIR/" 2>/dev/null || true
cp CONTRIBUTING.md "$INSTALL_DIR/" 2>/dev/null || true

# Copy sample deck if it doesn't exist in decks/
if [ -f "data/MCAT_High_Yield.apkg" ] && [ ! -f "$INSTALL_DIR/decks/MCAT_High_Yield.apkg" ]; then
    mkdir -p "$INSTALL_DIR/decks"
    cp "data/MCAT_High_Yield.apkg" "$INSTALL_DIR/decks/"
    echo "      ✓ Sample MCAT deck installed"
fi

echo "      ✓ Files installed to $INSTALL_DIR"

# Ensure decks directory exists
echo "[5/6] Setting up directories..."
mkdir -p "$INSTALL_DIR/decks"
echo "      ✓ Decks directory ready at $INSTALL_DIR/decks"

# Clean up
echo "[6/6] Cleaning up..."
rm -rf "$TEMP_DIR"
echo "      ✓ Temporary files removed"

echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "Installed components:"
echo "  - anki_viewer/     (main application)"
echo "  - app.py           (entrypoint)"
echo "  - requirements.txt (dependencies)"
echo "  - decks/           (your .apkg files go here)"
echo ""
echo "Next steps:"
echo "  1. Add your .apkg files to: $INSTALL_DIR/decks/"
echo "  2. Start the app: ./start-anki-viewer.sh"
echo "  3. Or restart if already running: ./dev-restart.sh"
echo ""
echo "Access at: http://$(hostname -i 2>/dev/null | awk '{print $1}'):5000"
echo ""
