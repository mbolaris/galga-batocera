#!/bin/bash
#
# Launch Anki Flashcard Viewer in Kodi Browser
# This script starts the Flask app and opens it in Kodi's web browser
#

set -e

APP_DIR="/userdata/roms/anki"
FLASK_URL="http://localhost:5000"

echo "========================================"
echo "  Anki Flashcard Viewer - Kodi Launcher"
echo "========================================"
echo ""

# Check if Flask app is running
if curl -s --connect-timeout 2 "$FLASK_URL" > /dev/null 2>&1; then
    echo "[✓] Flask app is already running"
else
    echo "[*] Starting Flask app..."
    cd "$APP_DIR"
    ./start-anki-viewer.sh > /tmp/anki-kodi.log 2>&1 &

    # Wait for Flask to start
    for i in {1..30}; do
        if curl -s --connect-timeout 1 "$FLASK_URL" > /dev/null 2>&1; then
            echo "[✓] Flask app started"
            break
        fi
        sleep 1
    done
fi

echo "[*] Launching Kodi with Anki viewer..."
echo ""

# Launch Kodi and open the web browser to the Flask app
# Kodi's web browser addon needs to be installed
kodi-send --action="ActivateWindow(webbrowser,$FLASK_URL)" 2>/dev/null || \
    kodi-standalone &

echo "========================================"
echo "  Kodi should now open to flashcards!"
echo "========================================"
echo ""
echo "URL: $FLASK_URL"
echo ""
echo "Press F1 or ESC in Kodi to exit"
echo ""
