#!/bin/bash
#
# Launch Kodi Web Browser to Anki Flashcards
# Run this from SSH to start studying without a keyboard
#

FLASK_URL="http://localhost:5000"
APP_DIR="/userdata/roms/anki"

echo "========================================"
echo "  Launching Anki Flashcards in Kodi"
echo "========================================"
echo ""

# Check if Flask is running, start if needed
if ! curl -s --connect-timeout 2 "$FLASK_URL/api/status" > /dev/null 2>&1; then
    echo "Starting Flask app..."
    cd "$APP_DIR"
    nohup ./start-anki-viewer.sh > /tmp/anki-kodi-ssh.log 2>&1 &

    echo "Waiting for Flask to start..."
    for i in {1..30}; do
        if curl -s --connect-timeout 1 "$FLASK_URL/api/status" > /dev/null 2>&1; then
            echo "✓ Flask ready!"
            break
        fi
        sleep 1
    done
else
    echo "✓ Flask is already running"
fi

echo ""
echo "Launching Kodi..."
echo ""

# Set display
export DISPLAY=:0.0

# Stop EmulationStation to free the display
batocera-es-swissknife --emukill 2>/dev/null

# Launch Kodi
KODI_CMD="/usr/bin/kodi-standalone"

if [ -x "$KODI_CMD" ]; then
    $KODI_CMD &
    KODI_PID=$!

    echo "========================================"
    echo "  Kodi is now running!"
    echo "========================================"
    echo ""
    echo "  In Kodi, navigate to:"
    echo "    Add-ons → Web Browser → $FLASK_URL"
    echo ""
    echo "  Or install Web Browser add-on if needed:"
    echo "    Add-ons → Get Add-ons → Program Add-ons"
    echo "    → Web Browser → Install"
    echo ""
    echo "  Flashcard controls:"
    echo "    Space = Flip card"
    echo "    ← →   = Navigate"
    echo "    R     = Random"
    echo "    ?     = Help"
    echo ""
    echo "  Press Ctrl+C here when done to restart ES"
    echo "========================================"

    # Wait for user to stop Kodi
    wait $KODI_PID
else
    echo "ERROR: Kodi not found at $KODI_CMD"
    exit 1
fi

# Restart EmulationStation
echo ""
echo "Restarting EmulationStation..."
batocera-es-swissknife --restart

echo "Done!"
