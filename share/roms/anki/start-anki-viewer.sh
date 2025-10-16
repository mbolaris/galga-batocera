#!/bin/bash
#
# Anki Deck Viewer Flask App - Launcher Script
# Place this in /userdata/roms/anki/ on Batocera
#
# This script sets up a self-contained Python venv and starts the Flask app
# on port 5000. All dependencies are installed locally.
#

set -e

# Change to the script's directory
cd "$(dirname "$0")"

APP_DIR="/userdata/roms/anki"
VENV_DIR="$APP_DIR/venv"
FLASK_APP="$APP_DIR/app.py"
DECK_PATH="$APP_DIR/decks"
PORT=5000

echo "========================================"
echo "  Anki Deck Viewer - Flask App Starter"
echo "========================================"
echo ""

# Step 1: Check if venv exists, create if not
if [ ! -d "$VENV_DIR" ]; then
    echo "[1/4] Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
    echo "      ✓ Virtual environment created at $VENV_DIR"
else
    echo "[1/4] Virtual environment already exists"
fi

# Step 2: Activate the venv
echo "[2/4] Activating virtual environment..."
source "$VENV_DIR/bin/activate"
echo "      ✓ Using Python: $(which python)"

# Step 3: Install/upgrade dependencies
echo "[3/4] Installing required packages..."
if [ -f "$APP_DIR/requirements.txt" ]; then
    pip install --upgrade pip -q
    pip install -r "$APP_DIR/requirements.txt" -q
    echo "      ✓ Packages installed from requirements.txt"
else
    echo "      ! Warning: requirements.txt not found"
    echo "      Installing minimal Flask setup..."
    pip install --upgrade pip -q
    pip install flask -q
fi

# Create decks directory if it doesn't exist
mkdir -p "$DECK_PATH"

# Step 4: Start the Flask app
echo "[4/4] Starting Flask app on port $PORT..."
echo ""
echo "========================================"
echo "  Access the app at:"
echo "  http://$(hostname -I | awk '{print $1}'):$PORT"
echo "  http://localhost:$PORT (local)"
echo "========================================"
echo ""
echo "  Deck path: $DECK_PATH"
echo "  Place your .apkg files in this directory"
echo ""
echo "========================================"
echo ""

# Check if app.py exists
if [ ! -f "$FLASK_APP" ]; then
    echo "ERROR: Flask app not found at $FLASK_APP"
    echo "Please create app.py in $APP_DIR"
    exit 1
fi

# Set environment variables for the Anki viewer
# ANKI_DATA_DIR: directory containing .apkg files (enables deck switching)
# ANKI_VIEWER_MEDIA_URL: URL path for serving media files
export ANKI_DATA_DIR="$DECK_PATH"
export ANKI_VIEWER_MEDIA_URL="/media"
unset ANKI_DECK_PATH  # Let it auto-discover from ANKI_DATA_DIR

# Start Flask directly with python
cd "$APP_DIR"
python app.py
