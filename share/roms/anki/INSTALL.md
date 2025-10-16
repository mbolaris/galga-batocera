# Quick Install Guide - Anki Flask App

## Summary
✅ Prompt 1: **COMPLETED** - Batocera basics documented in [agents.md](../../../agents.md)
✅ Prompt 2: **COMPLETED** - Flask app setup created

## What Was Created

All files are in `share/roms/anki/` and ready to copy to Batocera:

1. **start-anki-viewer.sh** - Main launcher (sets up venv, installs deps, starts Flask)
2. **requirements.txt** - Python dependencies (Flask, ankipandas, pandas, SQLAlchemy)
3. **app.py** - Starter Flask application with sample UI and API endpoints
4. **README.md** - Full documentation
5. **INSTALL.md** - This file (quick reference)

## Installation Steps

### Option 1: Copy via SMB (Recommended)

1. **Open Windows Explorer** and navigate to:
   ```
   \\BATOCERA\share\roms\anki
   ```
   (Replace BATOCERA with your device IP: `\\192.168.1.53\share\roms\anki`)

2. **Copy all files** from `c:\shared\bolaris\galga-batocera\share\roms\anki\` to the SMB share

3. **SSH into Batocera** and make the script executable:
   ```bash
   ssh root@192.168.1.53
   chmod +x /userdata/roms/anki/start-anki-viewer.sh
   ```

4. **Run the app:**
   ```bash
   cd /userdata/roms/anki
   ./start-anki-viewer.sh
   ```

### Option 2: Copy via SCP

From PowerShell on Windows:

```powershell
scp -r "c:\shared\bolaris\galga-batocera\share\roms\anki" root@192.168.1.53:/userdata/roms/
ssh root@192.168.1.53 "chmod +x /userdata/roms/anki/start-anki-viewer.sh"
```

## First Run

The first time you run the script, it will:
1. Create a Python virtual environment (`/userdata/roms/anki/venv`)
2. Install all dependencies from `requirements.txt` (~2-5 minutes)
3. Start Flask on port 5000

Subsequent runs are instant (venv already exists).

## Access the App

Once running, open in a browser:
- **From PC:** `http://192.168.1.53:5000`
- **From Batocera:** `http://localhost:5000`

## What You See

The starter app includes:
- Welcome page with setup instructions
- `/api/status` endpoint - Check app health
- `/api/decks` endpoint - List available Anki decks
- Sample code (commented) for reading Anki collections with ankipandas

## Next Steps

1. **Add your Anki decks:**
   - Place `.apkg`, `.anki2`, or Anki collection files in `/userdata/roms/anki/decks/`
   - Access via SMB: `\\192.168.1.53\share\roms\anki\decks\`

2. **Customize the app:**
   - Edit `app.py` to add deck reading/viewing functionality
   - Uncomment the example `/deck/<deck_name>` route
   - Add HTML templates in `templates/` folder if needed

3. **Test it:**
   - Visit `http://192.168.1.53:5000/api/decks` to see your deck files

## Troubleshooting

### Script won't run
```bash
chmod +x /userdata/roms/anki/start-anki-viewer.sh
```

### Python not found
Batocera should include Python 3. If not, update Batocera to a newer version.

### Out of space
Check available space:
```bash
df -h /userdata
```
The venv and packages need ~200-500MB.

### Port already in use
Change the port in `start-anki-viewer.sh`:
```bash
PORT=5001  # or any other port
```

## Files Created

```
share/roms/anki/
├── start-anki-viewer.sh   (launcher script)
├── requirements.txt       (Python dependencies)
├── app.py                 (Flask application)
├── README.md              (full documentation)
├── INSTALL.md             (this file)
└── venv/                  (created on first run)
    └── ...
```

## Architecture

This follows Batocera best practices:
- ✅ Self-contained (all deps in local venv)
- ✅ No system modifications (no apt, no base image changes)
- ✅ Lives in `/userdata` (persists across updates)
- ✅ Accessible via SMB share
- ✅ Portable and reproducible

## Support

See the main [README.md](README.md) for detailed documentation and examples.
