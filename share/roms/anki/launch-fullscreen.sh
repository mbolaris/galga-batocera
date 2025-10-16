#!/bin/bash
#
# Launch Anki Flashcard Viewer in Fullscreen
# Opens the Flask app in a simple fullscreen browser/viewer
#

set -e

APP_DIR="/userdata/roms/anki"
FLASK_URL="http://localhost:5000"
DISPLAY="${DISPLAY:-:0.0}"

echo "========================================"
echo "  Anki Flashcard Viewer Launcher"
echo "========================================"
echo ""

# Check if Flask app is running
if ! curl -s --connect-timeout 2 "$FLASK_URL/api/status" > /dev/null 2>&1; then
    echo "[1/3] Starting Flask app..."
    cd "$APP_DIR"
    nohup ./start-anki-viewer.sh > /tmp/anki-fullscreen.log 2>&1 &

    # Wait for Flask to start (up to 30 seconds)
    echo "      Waiting for Flask to start..."
    for i in {1..30}; do
        if curl -s --connect-timeout 1 "$FLASK_URL/api/status" > /dev/null 2>&1; then
            echo "      ✓ Flask app is ready"
            break
        fi
        sleep 1
        if [ $i -eq 30 ]; then
            echo "      ✗ Flask app failed to start"
            echo "      Check logs: /tmp/anki-fullscreen.log"
            exit 1
        fi
    done
else
    echo "[1/3] Flask app is already running ✓"
fi

echo "[2/3] Stopping EmulationStation..."
# Stop EmulationStation to free up the display
batocera-es-swissknife --emukill

# Small delay to ensure ES has stopped
sleep 2

echo "[3/3] Opening flashcards in fullscreen..."
echo ""
echo "========================================"
echo "  Flashcards Now Running!"
echo "========================================"
echo ""
echo "  URL: $FLASK_URL"
echo ""
echo "  Controls:"
echo "    Space    - Flip card"
echo "    → ←      - Navigate cards"
echo "    R        - Random card  "
echo "    ?        - Help"
echo ""
echo "  Press F1 or Ctrl+C to exit"
echo ""
echo "========================================"
echo ""

# Launch Kodi with the URL
export DISPLAY=$DISPLAY

echo "Opening Kodi..."
echo ""
echo "  Once in Kodi:"
echo "  1. Go to Add-ons"
echo "  2. Search for 'Web Browser' and install if needed"
echo "  3. Open Web Browser"
echo "  4. Navigate to: localhost:5000"
echo ""
echo "  Or simply remember to open: $FLASK_URL"
echo ""

# Launch Kodi
kodi-standalone 2>/dev/null &
KODI_PID=$!

# Wait for Kodi to exit
wait $KODI_PID

# Restart EmulationStation
echo ""
echo "Restarting EmulationStation..."
batocera-es-swissknife --restart

echo "Done!"
