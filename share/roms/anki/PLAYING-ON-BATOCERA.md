# Playing Flashcards Directly on GALAGA (Batocera Device)

This guide shows you how to study your Anki flashcards directly on your Batocera device's screen, not from a remote PC.

## Quick Start

### Option 1: From EmulationStation (Easiest)

1. **In EmulationStation** on GALAGA:
   - Navigate to **PORTS** in the main menu
   - Select **"Anki Flashcards"**
   - Press A/Enter to launch

2. **The app will**:
   - Start the Flask server automatically (if not running)
   - Stop EmulationStation temporarily
   - Open the flashcards in fullscreen (via Kodi or available browser)

3. **Study your cards!**
   - Use keyboard/controller:
     - `Space` - Flip card
     - `→` `←` - Navigate cards
     - `R` - Random card
     - `?` - Help overlay

4. **Exit**: Press F1, ESC, or Ctrl+C
   - EmulationStation will restart automatically

### Option 2: Manual Launch (SSH)

If you're SSH'd into GALAGA:

```bash
cd /userdata/roms/anki
./launch-fullscreen.sh
```

## What Happens Behind the Scenes

The launcher script (`launch-fullscreen.sh`) does this automatically:

1. **Checks if Flask is running** - starts it if needed
2. **Stops EmulationStation** - frees up the display
3. **Opens browser/Kodi** - launches flashcards in fullscreen
4. **On exit** - restarts EmulationStation

## Troubleshooting

### "No browser found"

If no browser is available, the script will:
- Show instructions for using Kodi manually
- Wait for you to press Enter

To use Kodi:
1. Exit the launcher (Ctrl+C)
2. Press F1 in EmulationStation
3. Go to Applications → Kodi
4. In Kodi, install the "Web Browser" add-on if needed
5. Navigate to: `http://localhost:5000`

### Flask won't start

Check the logs:
```bash
cat /tmp/anki-fullscreen.log
```

If the Flask app failed, manually start it:
```bash
cd /userdata/roms/anki
./start-anki-viewer.sh
```

### Screen is blank

The app might be running in the background. Check:
```bash
curl http://localhost:5000
```

If it returns HTML, the app is running. Try:
- Press Alt+Tab to switch windows
- Restart EmulationStation: `batocera-es-swissknife --restart`

## Adding Your Own Decks

Place `.apkg` files in:
```
/userdata/roms/anki/decks/
```

Or via SMB from Windows:
```
\\192.168.1.53\share\roms\anki\decks\
```

The app will auto-detect them!

## Remote Access

You can still access the flashcards from your PC while they're running on GALAGA:

**From PC browser**: `http://192.168.1.53:5000`

Both work at the same time - use whichever is more convenient!

## Files

- `/userdata/roms/anki/launch-fullscreen.sh` - Main launcher
- `/userdata/roms/ports/Anki Flashcards.sh` - EmulationStation port entry
- `/userdata/roms/anki/decks/` - Your .apkg files

## Notes

- **Performance**: The web interface is lightweight and should run smoothly
- **Exit cleanly**: Always use F1/ESC to exit, don't just power off
- **Auto-start**: The Flask server starts automatically when launching
- **Persistence**: Your deck files are safe in `/userdata`, they survive updates
