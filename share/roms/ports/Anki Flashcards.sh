#!/bin/bash
#
# Anki Flashcard Viewer - EmulationStation Port
# Starts Flask and opens in Kodi
#

FLASK_URL="http://localhost:5000"
APP_DIR="/userdata/roms/anki"

# Start Flask if not running
if ! curl -s --connect-timeout 2 "$FLASK_URL/api/status" > /dev/null 2>&1; then
    cd "$APP_DIR"
    ./start-anki-viewer.sh > /tmp/anki-port.log 2>&1 &

    # Wait for Flask to start (up to 30 seconds)
    for i in {1..30}; do
        if curl -s --connect-timeout 1 "$FLASK_URL/api/status" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
fi

# Create a simple instruction screen using dialog/whiptail
if command -v dialog >/dev/null 2>&1; then
    dialog --title "Anki Flashcards Ready!" \
           --msgbox "Flask server is running!\n\nTo access your flashcards:\n\n1. Exit this screen (OK)\n2. Press F1 for Batocera menu\n3. Go to Applications → Kodi\n4. In Kodi: Add-ons → Web Browser\n5. Navigate to: localhost:5000\n\nOr access from PC browser:\nhttp://192.168.1.53:5000\n\nControls:\n  Space = Flip card\n  ← →   = Navigate\n  R     = Random\n  ?     = Help" 20 60
elif command -v batocera-info >/dev/null 2>&1; then
    # Use Batocera's notification system
    batocera-info "Anki Flashcards" "Server running at http://localhost:5000\n\nOpen in Kodi: F1 → Applications → Kodi → Web Browser\n\nOr from PC: http://192.168.1.53:5000"
else
    # Fallback - just show a message
    clear
    echo "========================================"
    echo "  Anki Flashcards Server Running!"
    echo "========================================"
    echo ""
    echo "To access your flashcards:"
    echo ""
    echo "1. Press F1 for Batocera menu"
    echo "2. Go to Applications → Kodi"
    echo "3. In Kodi: Add-ons → Web Browser"
    echo "4. Navigate to: localhost:5000"
    echo ""
    echo "Or from your PC browser:"
    echo "  http://192.168.1.53:5000"
    echo ""
    echo "Press any key to return to menu..."
    read -n 1
fi

exit 0
