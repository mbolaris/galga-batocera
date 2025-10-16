# EmulationStation Integration Guide

This guide explains how to add the Anki Deck Viewer to EmulationStation's main menu so you can launch it like any other system/game.

## Overview

After integration, you'll see "Anki Deck Viewer" in the EmulationStation menu. Selecting it launches the Flask app in the background and opens it in a browser (Firefox/Chromium). When you close the browser, the Flask app automatically shuts down.

## Files Involved

1. **[anki-viewer.sh](anki-viewer.sh)** - EmulationStation launcher script
2. **[es_systems_anki.cfg](../../system/configs/emulationstation/es_systems_anki.cfg)** - System definition for ES

## Installation Steps

### Step 1: Copy Files to Batocera

#### Via SMB (Recommended)

1. **Copy the ES launcher script:**
   ```
   From: c:\shared\bolaris\galga-batocera\share\roms\anki\anki-viewer.sh
   To:   \\BATOCERA\share\roms\anki\anki-viewer.sh
   ```

2. **Copy the ES system config:**
   ```
   From: c:\shared\bolaris\galga-batocera\share\system\configs\emulationstation\es_systems_anki.cfg
   To:   \\BATOCERA\share\system\configs\emulationstation\es_systems_anki.cfg
   ```

#### Via SSH/SCP

```bash
# Copy launcher script (from Windows PowerShell)
scp "c:\shared\bolaris\galga-batocera\share\roms\anki\anki-viewer.sh" root@192.168.1.53:/userdata/roms/anki/

# Copy ES config
scp "c:\shared\bolaris\galga-batocera\share\system\configs\emulationstation\es_systems_anki.cfg" root@192.168.1.53:/userdata/system/configs/emulationstation/
```

### Step 2: Make Script Executable

SSH into Batocera:

```bash
ssh root@192.168.1.53
chmod +x /userdata/roms/anki/anki-viewer.sh
```

### Step 3: Verify Setup

Before restarting ES, ensure the Flask environment is set up:

```bash
# Run the initial setup (if not done already)
cd /userdata/roms/anki
./start-anki-viewer.sh
```

This creates the venv and installs dependencies. Press Ctrl+C to stop the Flask app after it starts (the ES launcher will manage it).

### Step 4: Restart EmulationStation

```bash
# Via SSH
systemctl restart emulationstation

# Or just reboot
reboot
```

Alternatively, press `Start` → `Quit` → `Restart EmulationStation` from the ES menu.

## How It Works

### System Definition (es_systems_anki.cfg)

Batocera automatically merges custom `es_systems_*.cfg` files from `/userdata/system/configs/emulationstation/` with the main configuration.

Our config defines:
- **System name:** `anki`
- **Display name:** "Anki Deck Viewer"
- **ROM path:** `/userdata/roms/anki`
- **Extensions:** `.sh` (only .sh scripts appear in the menu)
- **Command:** `bash %ROM%` (executes the script)
- **Theme:** `ports` (uses the ports system theme)

### Launcher Script (anki-viewer.sh)

The launcher script:
1. **Checks prerequisites** (venv exists, app.py exists)
2. **Activates the Python venv**
3. **Starts Flask in background** (saves PID for cleanup)
4. **Waits for Flask to be ready** (polls http://localhost:5000)
5. **Launches browser** (tries flatpak Firefox, system Firefox, Chromium, xdg-open)
6. **Waits for browser to close**
7. **Cleans up Flask process** (kills by PID, fallback pkill)

The cleanup is registered with `trap` so it runs even if the script is interrupted.

## Browser Options

The script tries browsers in this order:

1. **Firefox (flatpak)** - `flatpak run org.mozilla.firefox --kiosk`
2. **Firefox (system)** - `firefox --kiosk`
3. **Chromium** - `chromium --kiosk --app=`
4. **Default browser** - `xdg-open`

Kiosk mode provides a fullscreen experience without browser UI.

## Troubleshooting

### "Anki Deck Viewer" doesn't appear in ES menu

**Check the config file location:**
```bash
ls -la /userdata/system/configs/emulationstation/es_systems_anki.cfg
```

Should exist and be readable.

**Check the ROM directory:**
```bash
ls -la /userdata/roms/anki/
```

Should contain `anki-viewer.sh` (and it should be executable).

**Check ES logs:**
```bash
tail -f /userdata/system/logs/es_log.txt
```

Look for parsing errors or system loading issues.

**Force ES to rescan:**
- Press `Start` → `Game Settings` → `Update Gamelists`
- Or restart ES: `systemctl restart emulationstation`

### Script runs but browser doesn't open

**Check available browsers:**
```bash
which firefox
which chromium
flatpak list | grep firefox
```

Install Firefox via flatpak if needed:
```bash
flatpak install flathub org.mozilla.firefox
```

**Check the logs:**
```bash
cat /userdata/roms/anki/flask.log
```

### Flask app doesn't start

**Error: "Virtual environment not found"**

Run the initial setup:
```bash
cd /userdata/roms/anki
./start-anki-viewer.sh
```

**Error: "Flask app not found"**

Ensure `app.py` exists:
```bash
ls -la /userdata/roms/anki/app.py
```

**Check Python is available:**
```bash
which python3
python3 --version
```

### Browser opens but shows "Connection refused"

Flask may not be ready yet. The script waits 10 seconds, but on slower systems you might need more time.

**Increase wait time in anki-viewer.sh:**
```bash
MAX_WAIT=20  # Change from 10 to 20
```

**Check if Flask is running:**
```bash
ps aux | grep flask
netstat -tlnp | grep 5000
```

### Flask process doesn't stop after browser closes

**Manual cleanup:**
```bash
pkill -f "flask run"
rm /userdata/roms/anki/.flask.pid
```

**Check for orphaned processes:**
```bash
ps aux | grep python | grep flask
```

## Multiple Launch Scripts

You can create multiple launchers for different Anki decks or configurations:

```bash
/userdata/roms/anki/
  ├── anki-viewer.sh           # Main viewer
  ├── anki-deck-japanese.sh    # Specific deck launcher
  ├── anki-deck-spanish.sh     # Another deck
  └── ...
```

All `.sh` files in `/userdata/roms/anki/` will appear in EmulationStation.

**Example: Deck-specific launcher**

```bash
#!/bin/bash
# Launch Anki viewer with specific deck pre-loaded
export ANKI_DECK="/userdata/roms/anki/decks/japanese.apkg"
/userdata/roms/anki/anki-viewer.sh
```

You can modify `app.py` to check the `ANKI_DECK` environment variable and load that deck by default.

## Customization

### Change Port

Edit `anki-viewer.sh`:
```bash
PORT=5001  # Change from 5000
```

### Disable Kiosk Mode

Edit `anki-viewer.sh` and remove `--kiosk` flags:
```bash
firefox http://localhost:$PORT  # Normal browser window
```

### Add Custom Branding

Edit `app.py` to customize the web interface with your own HTML/CSS.

### Change System Display Name

Edit `es_systems_anki.cfg`:
```xml
<fullname>My Flashcard Viewer</fullname>
<description>Custom description here</description>
```

Then restart ES.

## Uninstallation

To remove the Anki system from EmulationStation:

1. **Remove the ES config:**
   ```bash
   rm /userdata/system/configs/emulationstation/es_systems_anki.cfg
   ```

2. **Restart EmulationStation:**
   ```bash
   systemctl restart emulationstation
   ```

The files in `/userdata/roms/anki/` remain untouched (you can still run the app manually).

To completely remove everything:
```bash
rm -rf /userdata/roms/anki
```

## Next Steps

- **Add custom decks** to `/userdata/roms/anki/decks/`
- **Customize the Flask app** in `app.py`
- **Set up development workflow** (see [DEVELOPMENT.md](DEVELOPMENT.md))
- **Add more launchers** for specific use cases

## References

- [Batocera EmulationStation Wiki](https://wiki.batocera.org/emulationstation)
- [Custom Systems Guide](https://wiki.batocera.org/add_games_custom_system)
- Main project: [README.md](README.md)
