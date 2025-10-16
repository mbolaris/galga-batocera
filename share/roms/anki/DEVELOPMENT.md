# Development Workflow Guide

Complete guide for developing and maintaining the Anki Viewer Flask app on Batocera from your Windows PC.

## Overview

This development workflow is designed for:
- **Windows PC** running VSCode with Claude Code/GitHub Copilot
- **Batocera device** running on Raspberry Pi (accessible via SSH and SMB)
- **Git-based** version control
- **Fast iteration** with minimal friction

## Architecture

```
Windows PC (Development)
├── VSCode with extensions
├── Git repository (this repo)
├── SMB access to \\BATOCERA\share
└── SSH access for deployment

Batocera Device (Runtime)
├── /userdata/roms/anki/ (app location)
├── Flask app in Python venv
└── Git repository (optional)
```

## Setup

### Prerequisites

1. **Windows PC:**
   - VSCode installed
   - Git installed
   - OpenSSH client (Windows 10+ includes it)
   - PowerShell 5.1+
   - Make (optional, via Git for Windows, Chocolatey, or WSL)

2. **Batocera Device:**
   - SSH enabled (default)
   - Network accessible (note the IP address)
   - Python 3 available (included in Batocera)

### Initial Setup

1. **Clone or create the repository:**
   ```powershell
   cd c:\shared\bolaris\galga-batocera
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. **Configure Batocera IP:**
   Edit `Makefile` or `dev-tools/deploy.ps1` and set:
   ```makefile
   BATOCERA_HOST = 192.168.1.53  # Your Batocera IP
   ```

3. **Test SSH connection:**
   ```powershell
   make test-ssh
   # or
   ssh root@192.168.1.53
   ```

4. **Deploy for the first time:**
   ```powershell
   make install-remote
   # or
   .\dev-tools\deploy.ps1 -Update
   ```

   This copies all files and sets up the venv with dependencies.

5. **Open workspace in VSCode:**
   ```powershell
   code c:\shared\bolaris\galga-batocera
   ```

   VSCode will prompt to install recommended extensions.

## Development Workflows

### Workflow 1: SMB Share Editing (Simplest)

**Best for:** Quick edits, HTML/CSS changes, testing

1. **Mount SMB share:**
   ```
   \\BATOCERA\share\roms\anki
   # or using IP:
   \\192.168.1.53\share\roms\anki
   ```

2. **Edit files directly** via Windows Explorer or VSCode:
   - Open `\\BATOCERA\share\roms\anki\app.py` in VSCode
   - Make changes
   - Auto-save is enabled (1 second delay)

3. **Restart Flask** to see changes:
   ```powershell
   make restart
   # or
   .\dev-tools\remote-cmd.ps1 restart
   ```

4. **View in browser:**
   ```
   http://192.168.1.53:5000
   ```

**Pros:** Instant file updates, no deployment step
**Cons:** Direct editing on production, no version control until you commit

### Workflow 2: Local Editing + Deploy (Recommended)

**Best for:** Feature development, version control, AI-assisted coding

1. **Edit files locally** in VSCode:
   ```
   c:\shared\bolaris\galga-batocera\share\roms\anki\app.py
   ```

2. **Test locally** (optional):
   - Press `F5` in VSCode to run Flask locally
   - Or: `Ctrl+Shift+P` → "Tasks: Run Task" → "Run Flask Locally"
   - Access at `http://localhost:5000`

3. **Deploy to Batocera:**
   ```powershell
   make restart
   # or press Ctrl+Shift+B in VSCode (runs default build task)
   ```

4. **View on Batocera:**
   ```
   http://192.168.1.53:5000
   ```

5. **Commit changes:**
   ```powershell
   git add .
   git commit -m "Added new feature"
   git push
   ```

**Pros:** Version control, local testing, clean workflow
**Cons:** Extra deploy step (but very fast)

### Workflow 3: Git-Based Development (Most Robust)

**Best for:** Team development, production deployments

1. **Set up Git on Batocera:**
   ```bash
   ssh root@192.168.1.53
   cd /userdata/roms/anki
   git init
   git remote add origin https://github.com/yourusername/anki-viewer.git
   # or use the local PC as remote
   ```

2. **Develop locally:**
   - Edit files in VSCode
   - Commit to Git
   - Push to remote (GitHub, GitLab, etc.)

3. **Update Batocera:**
   ```bash
   ssh root@192.168.1.53
   cd /userdata/roms/anki
   git pull
   ./dev-update.sh --skip-git  # Update deps if needed
   ./dev-restart.sh
   ```

   Or use the sync command:
   ```powershell
   make sync  # Commits, pushes, then pulls on Batocera
   ```

**Pros:** Proper version control, rollback capability, team-friendly
**Cons:** More steps, requires git on Batocera

## Development Tools

### Makefile Commands

Quick reference for `make` commands:

```powershell
# Deployment
make deploy         # Copy files to Batocera
make restart        # Deploy and restart Flask
make update         # Deploy and update dependencies

# App Management
make status         # Check if Flask is running
make logs           # View last 50 lines of logs
make logs-follow    # Follow logs in real-time (Ctrl+C to exit)
make stop           # Stop Flask app
make start          # Start Flask app

# Development
make shell          # Open SSH shell to Batocera
make test-ssh       # Test SSH connection
make clean-remote   # Clean logs and cache on Batocera

# Quick shortcuts
make dev            # Deploy, restart, and show info
make quick          # Deploy and restart (fast)
make full           # Full deployment with dependency update
```

### PowerShell Scripts

Located in `dev-tools/`:

#### deploy.ps1
```powershell
# Deploy files to Batocera
.\dev-tools\deploy.ps1

# Deploy to different host
.\dev-tools\deploy.ps1 -Host 192.168.1.100

# Deploy and restart Flask
.\dev-tools\deploy.ps1 -Restart

# Deploy and update dependencies
.\dev-tools\deploy.ps1 -Update
```

#### remote-cmd.ps1
```powershell
# Manage Flask app remotely
.\dev-tools\remote-cmd.ps1 restart      # Restart Flask
.\dev-tools\remote-cmd.ps1 stop         # Stop Flask
.\dev-tools\remote-cmd.ps1 status       # Check status
.\dev-tools\remote-cmd.ps1 logs         # View logs
.\dev-tools\remote-cmd.ps1 logs -Follow # Follow logs
.\dev-tools\remote-cmd.ps1 shell        # Open SSH shell
```

### Batocera-Side Scripts

Located in `/userdata/roms/anki/`:

#### dev-update.sh
```bash
# Update app from git and reinstall dependencies
./dev-update.sh

# Skip git pull, only update deps
./dev-update.sh --skip-git

# Only reinstall dependencies
./dev-update.sh --deps-only
```

#### dev-restart.sh
```bash
# Quickly restart Flask (for iterative development)
./dev-restart.sh
```

#### dev-stop.sh
```bash
# Stop Flask cleanly
./dev-stop.sh
```

### VSCode Integration

Press `Ctrl+Shift+P` and type "Tasks: Run Task", then select:

- **Deploy to Batocera** - Copy files
- **Deploy and Restart** - Copy files and restart Flask (Default: `Ctrl+Shift+B`)
- **Deploy and Update** - Copy files and update dependencies
- **Restart Flask** - Restart without deploying
- **Stop Flask** - Stop Flask app
- **Check Flask Status** - See if running
- **View Flask Logs** - Show recent logs
- **Follow Flask Logs** - Live log streaming
- **Open SSH Shell** - SSH into Batocera

Or press `F5` to run Flask locally for debugging.

## Common Development Tasks

### Adding a New Feature

1. **Create a feature branch:**
   ```powershell
   git checkout -b feature/new-deck-parser
   ```

2. **Edit app.py or add new files:**
   ```python
   # In app.py
   @app.route('/api/parse-deck')
   def parse_deck():
       # Your code here
       return jsonify({'status': 'ok'})
   ```

3. **Test locally:**
   Press `F5` in VSCode or run:
   ```powershell
   cd share\roms\anki
   python app.py
   ```

4. **Deploy and test on Batocera:**
   ```powershell
   make restart
   ```

5. **View logs:**
   ```powershell
   make logs-follow
   ```

6. **Commit and merge:**
   ```powershell
   git add .
   git commit -m "Add new deck parser endpoint"
   git checkout main
   git merge feature/new-deck-parser
   git push
   ```

### Adding Dependencies

1. **Edit requirements.txt:**
   ```
   flask>=3.0.0
   ankipandas>=0.3.10
   pandas>=2.0.0
   sqlalchemy>=2.0.0
   new-package>=1.0.0  # Add this
   ```

2. **Deploy and update:**
   ```powershell
   make update
   ```

   This will:
   - Copy the updated `requirements.txt`
   - Run `pip install -r requirements.txt --upgrade`
   - Restart Flask

3. **Or update manually via SSH:**
   ```bash
   ssh root@192.168.1.53
   cd /userdata/roms/anki
   source venv/bin/activate
   pip install new-package
   deactivate
   ./dev-restart.sh
   ```

### Debugging Issues

#### Check Flask Status
```powershell
make status
```

Shows:
- Running/stopped
- Port listening
- Venv installed
- App files present

#### View Logs
```powershell
make logs          # Last 50 lines
make logs-follow   # Live stream
```

#### SSH into Batocera
```powershell
make shell
```

Then:
```bash
# Check Flask process
ps aux | grep flask

# Check port
netstat -tlnp | grep 5000

# Test Flask directly
curl http://localhost:5000

# Check venv
ls -la venv/
source venv/bin/activate
pip list
deactivate

# View full logs
tail -f flask.log
```

#### Rebuild Environment
```bash
ssh root@192.168.1.53
cd /userdata/roms/anki

# Remove venv
rm -rf venv

# Redeploy
exit
make update
```

### Testing on Multiple Batocera Devices

If you have multiple devices:

```powershell
# Device 1
make deploy BATOCERA_HOST=192.168.1.53

# Device 2
make deploy BATOCERA_HOST=192.168.1.54

# Device 3
make deploy BATOCERA_HOST=192.168.1.55
```

Or set environment variable:
```powershell
$env:BATOCERA_HOST="192.168.1.54"
make deploy
```

## AI-Assisted Development (Claude Code / Copilot)

### Using Claude Code

Claude Code (you're using it now!) is great for:
- Generating Flask routes
- Writing Anki deck parsers
- Creating HTML templates
- Debugging issues

**Example prompts:**

```
"Add a new Flask route that lists all Anki decks in the decks/ folder"
"Parse an Anki .apkg file and display card counts"
"Create an HTML template with Bootstrap for displaying flashcards"
"Debug why Flask isn't starting - check the logs at share/roms/anki/flask.log"
```

**Workflow with Claude:**
1. Ask Claude to implement a feature
2. Claude edits `app.py` or creates new files
3. Claude can run `make restart` to deploy
4. Claude can check logs with `make logs`
5. Iterate until working

### Using GitHub Copilot

Copilot is great for:
- Autocompleting Python code
- Suggesting Flask decorators
- Writing ankipandas queries

**Tips:**
- Add comments describing what you want: `# Route to display deck statistics`
- Use descriptive function names: `def get_deck_card_count(deck_name):`
- Copilot will suggest the implementation

## Performance Tips

### Fast Iteration
For quickest dev loop:

```powershell
# Edit app.py in VSCode (auto-saves in 1 second)
# Then:
make quick  # Deploys and restarts in ~2-3 seconds

# Or even faster: edit via SMB and just restart
make cmd-restart  # ~1 second
```

### Skip Unnecessary Steps

```bash
# On Batocera, if only app.py changed:
./dev-restart.sh  # Skip dependency checks

# If dependencies changed:
./dev-update.sh --skip-git  # Update deps, skip git pull
```

### Use Make for Common Workflows

Create shortcuts in Makefile for your most common tasks:

```makefile
# Add to Makefile
.PHONY: my-workflow
my-workflow: deploy cmd-restart logs-follow
```

Then:
```powershell
make my-workflow
```

## Git Workflow

### Branching Strategy

```
main                 - Production-ready code
  ├── develop        - Development branch
  │   ├── feature/x  - Feature branches
  │   └── bugfix/y   - Bug fixes
```

### Common Commands

```powershell
# Start new feature
git checkout -b feature/deck-search
# ... make changes ...
git add .
git commit -m "Add deck search functionality"
git push origin feature/deck-search

# Create pull request on GitHub/GitLab
# After review and merge:
git checkout main
git pull
make sync  # Update Batocera
```

### .gitignore

Already configured to exclude:
- `venv/` - Virtual environment
- `__pycache__/` - Python cache
- `*.log` - Log files
- `.flask.pid` - PID files
- `decks/*.apkg` - Large deck files (add individually if needed)

## Backup and Restore

### Backup Batocera App

```bash
ssh root@192.168.1.53
cd /userdata/roms
tar czf anki-backup-$(date +%Y%m%d).tar.gz anki/
exit

scp root@192.168.1.53:/userdata/roms/anki-backup-*.tar.gz ./backups/
```

### Restore from Backup

```bash
scp ./backups/anki-backup-20250115.tar.gz root@192.168.1.53:/userdata/roms/
ssh root@192.168.1.53
cd /userdata/roms
tar xzf anki-backup-20250115.tar.gz
cd anki
./dev-restart.sh
```

## Production Deployment

For a more robust production setup:

1. **Use a production WSGI server:**
   Edit `requirements.txt`:
   ```
   gunicorn>=21.0.0
   ```

   Create `start-production.sh`:
   ```bash
   #!/bin/bash
   cd /userdata/roms/anki
   source venv/bin/activate
   gunicorn -w 4 -b 0.0.0.0:5000 app:app
   ```

2. **Set environment variables:**
   Create `.env`:
   ```bash
   FLASK_ENV=production
   SECRET_KEY=your-secret-key
   ```

3. **Add systemd service** (optional):
   Create `/userdata/system/custom.sh`:
   ```bash
   #!/bin/bash
   # Start Anki viewer on boot
   cd /userdata/roms/anki
   ./start-production.sh &
   ```

## Troubleshooting

### Deploy Script Fails

**Error:** "Cannot connect to host"
- Check Batocera is powered on and on network
- Verify IP address: `ping 192.168.1.53`
- Check SSH is enabled on Batocera

**Error:** "Permission denied (publickey)"
- You need password auth or SSH keys set up
- Use `ssh-copy-id root@192.168.1.53` to copy your key

### Flask Won't Start

**Check Python:**
```bash
ssh root@192.168.1.53
which python3
python3 --version
```

**Check venv:**
```bash
cd /userdata/roms/anki
ls -la venv/
source venv/bin/activate
pip list
```

**Rebuild venv:**
```bash
rm -rf venv
./dev-update.sh
```

### VSCode Tasks Don't Work

**PowerShell execution policy:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Check task output:**
- View → Output → Tasks
- Look for error messages

### SMB Access Issues

**Can't connect to `\\BATOCERA\share`:**
- Try IP: `\\192.168.1.53\share`
- Check network discovery is enabled
- Check Batocera's SMB is running: `systemctl status smbd`

## Next Steps

- **[ES-INTEGRATION.md](ES-INTEGRATION.md)** - Add to EmulationStation menu
- **[README.md](README.md)** - Main project documentation
- **[INSTALL.md](INSTALL.md)** - Installation guide

## Quick Reference Card

```
╔═══════════════════════════════════════════════════════════╗
║              Anki Viewer - Dev Quick Reference             ║
╠═══════════════════════════════════════════════════════════╣
║ Deploy & Restart:     make restart   or  Ctrl+Shift+B     ║
║ View Logs:            make logs-follow                     ║
║ Check Status:         make status                          ║
║ Stop Flask:           make stop                            ║
║ SSH Shell:            make shell                           ║
║ Test Locally:         F5 in VSCode                         ║
║                                                             ║
║ App URL:              http://192.168.1.53:5000            ║
║ SMB Path:             \\192.168.1.53\share\roms\anki       ║
║ Remote Path:          /userdata/roms/anki                  ║
╚═══════════════════════════════════════════════════════════╝
```
