#!/bin/bash
#
# Simple Anki Flashcard Launcher
# Just starts Flask and shows the URL - you open it manually in Kodi
#

APP_DIR="/userdata/roms/anki"
FLASK_URL="http://localhost:5000"

clear
echo "========================================"
echo "  Anki Flashcard Viewer"
echo "========================================"
echo ""

# Check if Flask app is running
if ! curl -s --connect-timeout 2 "$FLASK_URL/api/status" > /dev/null 2>&1; then
    echo "Starting Flask app..."
    cd "$APP_DIR"
    nohup ./start-anki-viewer.sh > /tmp/anki-simple.log 2>&1 &

    # Wait for Flask to start
    echo "Waiting for app to start..."
    for i in {1..30}; do
        if curl -s --connect-timeout 1 "$FLASK_URL/api/status" > /dev/null 2>&1; then
            echo "✓ Flask app is ready!"
            break
        fi
        sleep 1
    done
else
    echo "✓ Flask app is already running"
fi

echo ""
echo "========================================"
echo "  YOUR FLASHCARDS ARE READY!"
echo "========================================"
echo ""
echo "  URL: $FLASK_URL"
echo ""
echo "  TO OPEN:"
echo "  1. Press F1 to exit to Batocera menu"
echo "  2. Navigate to Applications"
echo "  3. Open Kodi"
echo "  4. In Kodi: Add-ons → Get Add-ons"
echo "     → Program Add-ons → Web Browser"
echo "  5. Install Web Browser if needed"
echo "  6. Open Web Browser add-on"
echo "  7. Type in address bar: localhost:5000"
echo ""
echo "  KEYBOARD CONTROLS:"
echo "    Space    - Flip card"
echo "    ← →      - Navigate"
echo "    R        - Random"
echo "    ?        - Help"
echo ""
echo "========================================"
echo ""
echo "Press Enter to continue..."
read

# Return to EmulationStation
exit 0
