# Anki Viewer - Quick Reference

## One-Line Commands

### Deploy & Run
```powershell
# First time setup
make install-remote

# Quick deploy and restart
make restart

# Full update (with dependencies)
make update
```

### Check Status
```powershell
make status         # Is Flask running?
make logs           # Last 50 lines
make logs-follow    # Live logs (Ctrl+C to exit)
```

### Control Flask
```powershell
make stop           # Stop Flask
make start          # Start Flask
make cmd-restart    # Restart Flask
```

### Development
```powershell
make shell          # SSH into Batocera
make deploy         # Deploy files only
make test-ssh       # Test connection
```

## VSCode Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+B` | Deploy and restart (default build) |
| `F5` | Run Flask locally (debug mode) |
| `Ctrl+Shift+P` → "Tasks: Run Task" | Show all tasks |

## Makefile Commands (Full List)

```bash
make help           # Show all commands
make deploy         # Deploy files to Batocera
make restart        # Deploy and restart Flask
make update         # Deploy and update dependencies
make status         # Check Flask status
make logs           # View Flask logs (last 50 lines)
make logs-follow    # Follow Flask logs in real-time
make stop           # Stop Flask app
make start          # Start Flask app
make cmd-restart    # Restart Flask (no deploy)
make shell          # Open SSH shell to Batocera
make test-ssh       # Test SSH connection
make clean-remote   # Clean logs and cache on Batocera
make dev            # Deploy, restart, show info
make quick          # Quick deploy and restart
make full           # Full deployment with deps
make install-remote # First-time installation
make info           # Show project info
```

## PowerShell Scripts

### deploy.ps1
```powershell
# Basic deploy
.\dev-tools\deploy.ps1

# Deploy and restart
.\dev-tools\deploy.ps1 -Restart

# Deploy and update dependencies
.\dev-tools\deploy.ps1 -Update

# Deploy to different host
.\dev-tools\deploy.ps1 -Host 192.168.1.100

# Show help
.\dev-tools\deploy.ps1 -Help
```

### remote-cmd.ps1
```powershell
# Restart Flask
.\dev-tools\remote-cmd.ps1 restart

# Stop Flask
.\dev-tools\remote-cmd.ps1 stop

# Check status
.\dev-tools\remote-cmd.ps1 status

# View logs
.\dev-tools\remote-cmd.ps1 logs

# Follow logs
.\dev-tools\remote-cmd.ps1 logs -Follow

# Open SSH shell
.\dev-tools\remote-cmd.ps1 shell
```

## Batocera Scripts (SSH)

```bash
# Update from git and reinstall dependencies
./dev-update.sh

# Update dependencies only (skip git)
./dev-update.sh --skip-git

# Reinstall dependencies only
./dev-update.sh --deps-only

# Quick restart Flask
./dev-restart.sh

# Stop Flask
./dev-stop.sh

# Initial setup (creates venv, installs deps)
./start-anki-viewer.sh

# Launch from EmulationStation (with browser)
./anki-viewer.sh
```

## SSH Commands

```bash
# Connect to Batocera
ssh root@192.168.1.53

# Check Flask status
ps aux | grep flask
netstat -tlnp | grep 5000

# View logs
cd /userdata/roms/anki
tail -f flask.log

# Check venv
ls -la venv/
source venv/bin/activate
pip list
deactivate

# Manual Flask control
pkill -f "flask run"
cd /userdata/roms/anki && ./dev-restart.sh
```

## Git Workflow

```bash
# Initialize git on Batocera
ssh root@192.168.1.53
cd /userdata/roms/anki
git init
git remote add origin <your-repo-url>

# Update from git
ssh root@192.168.1.53
cd /userdata/roms/anki
git pull
./dev-update.sh --skip-git
./dev-restart.sh
```

Or use the sync command:
```powershell
make sync  # Commits, pushes, pulls on Batocera, restarts
```

## EmulationStation Integration

```bash
# Deploy ES config
scp share\system\configs\emulationstation\es_systems_anki.cfg root@192.168.1.53:/userdata/system/configs/emulationstation/

# Restart EmulationStation
ssh root@192.168.1.53 "systemctl restart emulationstation"
```

## Access URLs

```
Web App:       http://192.168.1.53:5000
SMB Share:     \\192.168.1.53\share\roms\anki
SSH:           ssh root@192.168.1.53
Remote Path:   /userdata/roms/anki
Local Path:    c:\shared\bolaris\galga-batocera\share\roms\anki
```

## Troubleshooting

### Flask won't start
```bash
ssh root@192.168.1.53
cd /userdata/roms/anki
rm -rf venv
./dev-update.sh
```

### Can't connect via SSH
```powershell
# Test connection
ping 192.168.1.53
ssh -v root@192.168.1.53

# Copy SSH key
ssh-copy-id root@192.168.1.53
```

### Deploy fails
```powershell
# Check SSH connection
make test-ssh

# Check local files
ls share\roms\anki\

# Check remote space
ssh root@192.168.1.53 "df -h /userdata"
```

### Flask is running but can't access
```bash
# Check if port is listening
ssh root@192.168.1.53 "netstat -tlnp | grep 5000"

# Check firewall (Batocera usually has no firewall)
# Try from Batocera itself
ssh root@192.168.1.53 "curl http://localhost:5000"
```

## File Locations

### Windows PC
```
c:\shared\bolaris\galga-batocera\
├── share\roms\anki\              # App files
├── dev-tools\                    # PowerShell scripts
├── .vscode\                      # VSCode settings
├── Makefile                      # Make commands
└── README.md                     # Documentation
```

### Batocera Device
```
/userdata/
├── roms/anki/                    # App files (deployed here)
│   ├── app.py
│   ├── start-anki-viewer.sh
│   ├── anki-viewer.sh
│   ├── dev-*.sh
│   ├── requirements.txt
│   ├── venv/                     # Python virtual environment
│   └── decks/                    # Anki deck files
└── system/configs/emulationstation/
    └── es_systems_anki.cfg       # ES system definition
```

## Development Workflows

### Workflow 1: SMB Editing (Fastest)
```
1. Mount \\192.168.1.53\share\roms\anki
2. Edit app.py in VSCode
3. make cmd-restart (or Ctrl+Shift+B)
4. Refresh browser
```

### Workflow 2: Local + Deploy (Recommended)
```
1. Edit c:\shared\bolaris\galga-batocera\share\roms\anki\app.py
2. make restart (or Ctrl+Shift+B)
3. View at http://192.168.1.53:5000
4. git commit && git push
```

### Workflow 3: Git-Based (Team)
```
1. Edit locally, commit, push to GitHub
2. ssh root@192.168.1.53
3. cd /userdata/roms/anki && git pull
4. ./dev-update.sh --skip-git && ./dev-restart.sh
```

## Common Tasks

### Add a new Python dependency
```bash
# Edit requirements.txt
code share\roms\anki\requirements.txt

# Deploy and update
make update
```

### View live logs during development
```powershell
# Terminal 1: Follow logs
make logs-follow

# Terminal 2: Deploy and restart
make restart
```

### Test changes quickly
```powershell
# Edit app.py
code share\roms\anki\app.py

# Deploy and restart (2-3 seconds)
make quick
```

### Deploy to multiple devices
```powershell
make deploy BATOCERA_HOST=192.168.1.53
make deploy BATOCERA_HOST=192.168.1.54
make deploy BATOCERA_HOST=192.168.1.55
```

## Environment Variables

```powershell
# Set custom Batocera IP
$env:BATOCERA_HOST="192.168.1.100"
make deploy

# Or edit Makefile
notepad Makefile
# Change: BATOCERA_HOST = 192.168.1.53
```

## Documentation

| File | Description |
|------|-------------|
| [README.md](README.md) | Main project overview |
| [agents.md](agents.md) | Batocera development guidelines |
| [share/roms/anki/README.md](share/roms/anki/README.md) | App overview |
| [share/roms/anki/INSTALL.md](share/roms/anki/INSTALL.md) | Installation guide |
| [share/roms/anki/DEVELOPMENT.md](share/roms/anki/DEVELOPMENT.md) | Complete dev workflow (6000+ words) |
| [share/roms/anki/ES-INTEGRATION.md](share/roms/anki/ES-INTEGRATION.md) | EmulationStation setup |
| [PROMPTS-SUMMARY.md](PROMPTS-SUMMARY.md) | Implementation summary |
| [QUICK-REFERENCE.md](QUICK-REFERENCE.md) | This file |

## Version Control

```bash
# Commit changes
git add .
git commit -m "Description of changes"
git push

# Create feature branch
git checkout -b feature/new-feature
# ... make changes ...
git commit -am "Add new feature"
git push origin feature/new-feature

# Merge to main
git checkout main
git merge feature/new-feature
git push
```

## Production Deployment

```bash
# Use Gunicorn instead of Flask dev server
# Edit requirements.txt
echo "gunicorn>=21.0.0" >> share/roms/anki/requirements.txt

# Create production start script
cat > share/roms/anki/start-production.sh << 'EOF'
#!/bin/bash
cd /userdata/roms/anki
source venv/bin/activate
gunicorn -w 4 -b 0.0.0.0:5000 app:app
EOF

# Deploy
make update
ssh root@192.168.1.53 "chmod +x /userdata/roms/anki/start-production.sh"
```

## Backup & Restore

```bash
# Backup Batocera app
ssh root@192.168.1.53
cd /userdata/roms
tar czf anki-backup-$(date +%Y%m%d).tar.gz anki/
exit
scp root@192.168.1.53:/userdata/roms/anki-backup-*.tar.gz ./backups/

# Restore
scp ./backups/anki-backup-20250115.tar.gz root@192.168.1.53:/userdata/roms/
ssh root@192.168.1.53 "cd /userdata/roms && tar xzf anki-backup-20250115.tar.gz"
```

## Help

```powershell
make help                           # Show all make commands
.\dev-tools\deploy.ps1 -Help        # Deploy script help
.\dev-tools\remote-cmd.ps1 -Help    # Remote command help (if implemented)
```

## Contact

Repository owner: mbolaris
