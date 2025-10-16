# Anki Deck Viewer - Flask App for Batocera

A self-contained Flask web application for viewing Anki decks on Batocera Linux.

## Architecture

This app follows Batocera best practices:
- **Self-contained**: All dependencies are installed in a local Python venv
- **Persistent**: Lives in `/userdata/roms/anki` which survives system updates
- **No system modifications**: Doesn't require apt or system package changes
- **Portable**: Can be copied via SMB share (`\\BATOCERA\share\roms\anki`)

## Files

- `start-anki-viewer.sh` - Main launcher script (sets up venv, installs deps, starts Flask)
- `requirements.txt` - Python package dependencies (Flask, ankipandas, etc.)
- `app.py` - Flask application (you need to create this)
- `venv/` - Python virtual environment (auto-created on first run)

## Installation

### From Windows PC (via SMB)

1. **Copy files to Batocera share:**
   ```
   \\BATOCERA\share\roms\anki\
   ```
   Copy all files from this directory to the share location.

2. **SSH into Batocera** and make the script executable:
   ```bash
   ssh root@<batocera-ip>
   chmod +x /userdata/roms/anki/start-anki-viewer.sh
   ```

3. **Create your Flask app** (`app.py`):
   You need to create the actual Flask application. Minimal example:
   ```python
   from flask import Flask, render_template
   import ankipandas as apd

   app = Flask(__name__)

   @app.route('/')
   def index():
       return "Anki Deck Viewer - Coming Soon!"

   if __name__ == '__main__':
       app.run(host='0.0.0.0', port=5000)
   ```

4. **Run the app:**
   ```bash
   cd /userdata/roms/anki
   ./start-anki-viewer.sh
   ```

## First Run

On first run, the script will:
1. Create a Python virtual environment in `/userdata/roms/anki/venv`
2. Upgrade pip
3. Install all packages from `requirements.txt` (Flask, ankipandas, pandas, etc.)
4. Start the Flask development server on port 5000

This takes a few minutes the first time. Subsequent runs are much faster.

## Accessing the App

Once running, access the web interface at:
- From Batocera: `http://localhost:5000`
- From your network: `http://<batocera-ip>:5000`

The script will display the exact URL when it starts.

## Adding to EmulationStation (Optional)

To launch the app from the EmulationStation menu:

1. The script is already in `/userdata/roms/anki/` (or a custom ports directory)
2. Ensure it's executable: `chmod +x start-anki-viewer.sh`
3. Add a ports system definition if you want it to appear in ES (see main repo README-ports.md)

Alternatively, just run it via SSH whenever you need it.

## Troubleshooting

### Python not found
Batocera should include Python 3. If not available, you may need to:
- Update Batocera to a newer version
- Use a different architecture (this is designed for standard Batocera images)

### Packages fail to install
- Ensure `/userdata` has enough space (check with `df -h`)
- Some packages may need compilation; if ankipandas fails, try installing just Flask first

### Cannot access from network
- Check firewall rules on Batocera
- Ensure the Flask app is binding to `0.0.0.0` (not just `127.0.0.1`)

## Development

To modify the Flask app:
1. Edit `app.py` directly via SMB (`\\BATOCERA\share\roms\anki\app.py`)
2. Stop and restart `start-anki-viewer.sh`
3. The venv persists, so dependency installs only happen once

## Updating Dependencies

To add new Python packages:
1. Edit `requirements.txt`
2. Delete the venv: `rm -rf /userdata/roms/anki/venv`
3. Run the script again - it will rebuild the venv with new packages

Or, manually update:
```bash
source /userdata/roms/anki/venv/bin/activate
pip install <new-package>
```

## Security Notes

- This runs as root (standard on Batocera)
- Flask development server is used (not for production, fine for local/home use)
- No authentication is configured - anyone on your network can access it
- Don't expose port 5000 to the internet without adding security

## References

- [Batocera Documentation](https://wiki.batocera.org/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [ankipandas Documentation](https://github.com/klieret/ankipandas)

## Next Steps

1. Create your `app.py` with the desired functionality
2. Add Anki deck files to a known location (e.g., `/userdata/roms/anki/decks/`)
3. Update the Flask app to read and display deck data
4. Optionally add HTML templates in `templates/` folder
5. Optionally add static files (CSS/JS) in `static/` folder
