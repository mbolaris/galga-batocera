# 🎉 Deployment Complete!

The Anki Deck Viewer has been successfully deployed to your Batocera device (GALAGA - 192.168.1.53).

## ✅ What's Installed

All files are deployed to `/userdata/roms/anki/`:
- ✅ Flask application (`app.py`)
- ✅ Python virtual environment with all dependencies
- ✅ All launcher scripts (`.sh` files)
- ✅ EmulationStation configuration
- ✅ Complete documentation

## 🌐 Access the App

### Quick Start
```
http://192.168.1.53:5000
```

Open this URL in your browser to see the Anki Deck Viewer!

### Running the App

**Option 1: Manual Start (Current)**
```bash
ssh root@192.168.1.53
cd /userdata/roms/anki
./start-anki-viewer.sh
```
Then visit http://192.168.1.53:5000

**Option 2: EmulationStation (Recommended)**
1. Restart EmulationStation:
   ```bash
   ssh root@192.168.1.53 "systemctl restart emulationstation"
   ```
2. Navigate to "Anki Deck Viewer" in the ES menu
3. Select "anki-viewer.sh"
4. Flask starts automatically and browser opens

## 🔧 Important: Line Endings Fixed

There was a line ending issue (Windows CRLF vs Unix LF) that has been fixed. All `.sh` scripts now have Unix line endings.

**For future deployments from Windows**, you need to fix line endings after copying files:

```bash
ssh root@192.168.1.53 "cd /userdata/roms/anki && dos2unix *.sh"
```

Or use the VSCode setting that's already configured (`.vscode/settings.json`):
```json
"files.eol": "\n"
```

## 📋 Next Steps

### 1. Test the Web Interface

Visit **http://192.168.1.53:5000** in your browser. You should see:
- Welcome page with app info
- API endpoints:
  - `/api/status` - App health check
  - `/api/decks` - List Anki decks

### 2. Add Anki Decks

Copy your `.apkg` or Anki collection files to:
```
\\192.168.1.53\share\roms\anki\decks\
```

Or via SSH:
```bash
scp mydeck.apkg root@192.168.1.53:/userdata/roms/anki/decks/
```

### 3. Enable EmulationStation Integration

Restart EmulationStation to add "Anki Deck Viewer" to the menu:
```bash
ssh root@192.168.1.53 "systemctl restart emulationstation"
```

Then you can launch the app from the ES menu like any other game/app!

### 4. Customize the App

Edit `app.py` to add your desired functionality:
- Parse Anki decks with `ankipandas`
- Display flashcards
- Add search functionality
- Create HTML templates in `templates/` folder

## 🔑 SSH Key Authentication (Optional but Recommended)

Currently, you're entering the password "linux" for each SSH connection. To enable password-less authentication:

The SSH key has been generated and added to Batocera, but it's not working yet. This might be a Batocera SSH configuration issue. For now, you can:

**Option A: Keep using password**
- It's just "linux" (default)
- Quick for occasional use

**Option B: Investigate SSH config**
```bash
# On Batocera, check SSH config
ssh root@192.168.1.53
find /etc -name "sshd_config" 2>/dev/null
# Check if PubkeyAuthentication is enabled
```

## 🛠️ Development Workflow

Now that everything is deployed, use these commands for development:

### Quick Edits (Fastest - 2 sec iteration)

1. Mount SMB share:
   ```
   \\192.168.1.53\share\roms\anki
   ```
2. Edit `app.py` in VSCode (auto-saves)
3. Restart Flask:
   ```powershell
   ssh root@192.168.1.53 "cd /userdata/roms/anki && ./dev-restart.sh"
   ```

### Local Development (Recommended - 3 sec iteration)

1. Edit files locally:
   ```
   c:\shared\bolaris\galga-batocera\share\roms\anki\app.py
   ```
2. Deploy and restart:
   ```powershell
   # Manual SCP
   scp share\roms\anki\app.py root@192.168.1.53:/userdata/roms/anki/
   ssh root@192.168.1.53 "cd /userdata/roms/anki && dos2unix *.sh && ./dev-restart.sh"
   ```

**Note:** The Makefile commands won't work until SSH key auth is fixed, but you can use manual scp/ssh commands as shown above.

### Using the Makefile (After SSH Keys Work)

```powershell
make deploy         # Copy files
make restart        # Copy and restart Flask
make status         # Check if running
make logs           # View logs
make shell          # SSH into Batocera
```

## 📁 File Locations

### On Windows PC
```
c:\shared\bolaris\galga-batocera\
├── share\roms\anki\          # Edit files here
│   ├── app.py               # Flask application
│   ├── *.sh                 # Shell scripts
│   └── requirements.txt     # Python dependencies
├── dev-tools\                # PowerShell scripts
├── Makefile                  # Development commands
└── .vscode\                  # VSCode settings
```

### On Batocera (GALAGA)
```
/userdata/
├── roms/anki/                # Deployed app
│   ├── app.py
│   ├── venv/                 # Python environment (created)
│   ├── *.sh                  # Executable scripts
│   └── decks/                # Place Anki files here
└── system/configs/emulationstation/
    └── es_systems_anki.cfg   # ES configuration
```

## 🐛 Troubleshooting

### Flask Won't Start
```bash
ssh root@192.168.1.53
cd /userdata/roms/anki
rm -rf venv
./start-anki-viewer.sh
```

### "Command not found" or "syntax error" in Scripts
```bash
# Fix line endings
ssh root@192.168.1.53 "cd /userdata/roms/anki && dos2unix *.sh"
```

### Can't Access Web Interface
```bash
# Check if Flask is running
ssh root@192.168.1.53 "ps aux | grep flask"
ssh root@192.168.1.53 "netstat -tlnp | grep 5000"

# Restart Flask
ssh root@192.168.1.53 "cd /userdata/roms/anki && ./dev-restart.sh"
```

### Deployment Issues
Remember to fix line endings after every file copy from Windows:
```bash
ssh root@192.168.1.53 "cd /userdata/roms/anki && dos2unix *.sh"
```

## 📚 Documentation

| File | Description |
|------|-------------|
| [README.md](README.md) | Main project overview |
| [share/roms/anki/README.md](share/roms/anki/README.md) | App overview |
| [share/roms/anki/INSTALL.md](share/roms/anki/INSTALL.md) | Installation guide |
| [share/roms/anki/DEVELOPMENT.md](share/roms/anki/DEVELOPMENT.md) | Complete dev workflow |
| [share/roms/anki/ES-INTEGRATION.md](share/roms/anki/ES-INTEGRATION.md) | EmulationStation setup |
| [QUICK-REFERENCE.md](QUICK-REFERENCE.md) | Command reference |
| [PROMPTS-SUMMARY.md](PROMPTS-SUMMARY.md) | Implementation details |

## 🎯 Quick Commands Reference

```powershell
# Access the app
Start http://192.168.1.53:5000

# SSH into Batocera
ssh root@192.168.1.53

# Restart Flask
ssh root@192.168.1.53 "cd /userdata/roms/anki && ./dev-restart.sh"

# Stop Flask
ssh root@192.168.1.53 "cd /userdata/roms/anki && ./dev-stop.sh"

# View logs
ssh root@192.168.1.53 "tail -f /userdata/roms/anki/flask.log"

# Restart EmulationStation
ssh root@192.168.1.53 "systemctl restart emulationstation"

# Copy files (manual)
scp share\roms\anki\app.py root@192.168.1.53:/userdata/roms/anki/
ssh root@192.168.1.53 "cd /userdata/roms/anki && dos2unix app.py"
```

## ✨ What's Working

- ✅ Flask app deployed and tested
- ✅ Python venv created with all dependencies
- ✅ Web interface accessible at http://192.168.1.53:5000
- ✅ All scripts have correct permissions
- ✅ Line endings fixed for Unix compatibility
- ✅ EmulationStation config deployed
- ✅ Documentation complete
- ✅ Development workflow established

## 🔄 What Needs Manual Steps

- ⚠️ SSH key authentication (optional, for password-less access)
- ⚠️ EmulationStation restart (to see "Anki Deck Viewer" in menu)
- ⚠️ Line ending conversion after Windows file edits (use dos2unix)

## 🚀 You're Ready!

Everything is deployed and working. You can now:

1. **Use the app:** http://192.168.1.53:5000
2. **Develop locally:** Edit `app.py` and deploy changes
3. **Add Anki decks:** Copy files to `decks/` folder
4. **Launch from ES:** After restarting EmulationStation

Enjoy your Anki Deck Viewer on Batocera! 🎉
