# Makefile for Anki Viewer Development on Batocera
#
# This Makefile provides convenient shortcuts for deploying and managing
# the Flask app on Batocera from your Windows development machine.
#
# Requirements:
#   - PowerShell (Windows)
#   - SSH access to Batocera
#   - OpenSSH client (ssh, scp commands available)
#
# Usage:
#   make deploy         Deploy files to Batocera
#   make restart        Deploy and restart Flask
#   make update         Deploy and update dependencies
#   make logs           View Flask logs
#   make status         Check Flask status
#   make stop           Stop Flask app
#   make shell          Open SSH shell to Batocera

# Configuration
BATOCERA_HOST ?= 192.168.1.53
BATOCERA_USER ?= root
BATOCERA_PATH = /userdata/roms/anki

# PowerShell executable
POWERSHELL = powershell.exe -ExecutionPolicy Bypass -File

# Default target
.PHONY: help
help:
	@echo "========================================"
	@echo "  Anki Viewer - Development Commands"
	@echo "========================================"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy         - Deploy files to Batocera"
	@echo "  make restart        - Deploy and restart Flask"
	@echo "  make update         - Deploy and update dependencies"
	@echo ""
	@echo "App Management:"
	@echo "  make status         - Check Flask status"
	@echo "  make logs           - View Flask logs (last 50 lines)"
	@echo "  make logs-follow    - Follow Flask logs in real-time"
	@echo "  make stop           - Stop Flask app"
	@echo "  make start          - Start Flask app"
	@echo ""
	@echo "Development:"
	@echo "  make shell          - Open SSH shell to Batocera"
	@echo "  make test-ssh       - Test SSH connection"
	@echo "  make clean-remote   - Clean logs and cache on Batocera"
	@echo ""
	@echo "Configuration:"
	@echo "  BATOCERA_HOST=$(BATOCERA_HOST)"
	@echo "  BATOCERA_USER=$(BATOCERA_USER)"
	@echo ""
	@echo "Override with:"
	@echo "  make deploy BATOCERA_HOST=192.168.1.100"
	@echo ""

# Deployment targets
.PHONY: deploy
deploy:
	@echo "Deploying to $(BATOCERA_HOST)..."
	@$(POWERSHELL) dev-tools\deploy.ps1 -Host $(BATOCERA_HOST) -User $(BATOCERA_USER)

.PHONY: restart
restart:
	@echo "Deploying and restarting Flask..."
	@$(POWERSHELL) dev-tools\deploy.ps1 -Host $(BATOCERA_HOST) -User $(BATOCERA_USER) -Restart

.PHONY: update
update:
	@echo "Deploying and updating dependencies..."
	@$(POWERSHELL) dev-tools\deploy.ps1 -Host $(BATOCERA_HOST) -User $(BATOCERA_USER) -Update

# App management targets
.PHONY: status
status:
	@$(POWERSHELL) dev-tools\remote-cmd.ps1 status -Host $(BATOCERA_HOST) -User $(BATOCERA_USER)

.PHONY: logs
logs:
	@$(POWERSHELL) dev-tools\remote-cmd.ps1 logs -Host $(BATOCERA_HOST) -User $(BATOCERA_USER)

.PHONY: logs-follow
logs-follow:
	@$(POWERSHELL) dev-tools\remote-cmd.ps1 logs -Host $(BATOCERA_HOST) -User $(BATOCERA_USER) -Follow

.PHONY: stop
stop:
	@$(POWERSHELL) dev-tools\remote-cmd.ps1 stop -Host $(BATOCERA_HOST) -User $(BATOCERA_USER)

.PHONY: start
start:
	@$(POWERSHELL) dev-tools\remote-cmd.ps1 start -Host $(BATOCERA_HOST) -User $(BATOCERA_USER)

.PHONY: cmd-restart
cmd-restart:
	@$(POWERSHELL) dev-tools\remote-cmd.ps1 restart -Host $(BATOCERA_HOST) -User $(BATOCERA_USER)

# Development targets
.PHONY: shell
shell:
	@$(POWERSHELL) dev-tools\remote-cmd.ps1 shell -Host $(BATOCERA_HOST) -User $(BATOCERA_USER)

.PHONY: test-ssh
test-ssh:
	@echo "Testing SSH connection to $(BATOCERA_USER)@$(BATOCERA_HOST)..."
	@ssh -o ConnectTimeout=5 $(BATOCERA_USER)@$(BATOCERA_HOST) "echo 'SSH connection successful!'"

.PHONY: clean-remote
clean-remote:
	@echo "Cleaning logs and cache on Batocera..."
	@ssh $(BATOCERA_USER)@$(BATOCERA_HOST) "cd $(BATOCERA_PATH) && rm -f *.log .flask.pid && find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true"
	@echo "Done."

# Quick shortcuts (common workflows)
.PHONY: dev
dev: restart
	@echo ""
	@echo "Development mode active!"
	@echo "  App: http://$(BATOCERA_HOST):5000"
	@echo "  Logs: make logs-follow"
	@echo ""

.PHONY: quick
quick: deploy cmd-restart

.PHONY: full
full: update
	@echo ""
	@echo "Full deployment complete!"
	@echo "  App: http://$(BATOCERA_HOST):5000"
	@echo ""

# Git workflow helpers
.PHONY: git-push
git-push:
	@echo "Committing and pushing changes..."
	@git add -A
	@git status
	@echo ""
	@echo "Enter commit message:"
	@read -p "> " msg && git commit -m "$$msg" && git push

.PHONY: sync
sync: git-push
	@echo ""
	@echo "Syncing to Batocera..."
	@ssh $(BATOCERA_USER)@$(BATOCERA_HOST) "cd $(BATOCERA_PATH) && git pull && ./dev-update.sh --skip-git && ./dev-restart.sh"
	@echo ""
	@echo "Sync complete!"

# Install/setup targets
.PHONY: install-remote
install-remote:
	@echo "Installing Anki Viewer on Batocera..."
	@$(POWERSHELL) dev-tools\deploy.ps1 -Host $(BATOCERA_HOST) -User $(BATOCERA_USER) -Update
	@echo ""
	@echo "Installation complete!"
	@echo "Configure EmulationStation:"
	@echo "  1. Ensure es_systems_anki.cfg is deployed"
	@echo "  2. Restart EmulationStation: systemctl restart emulationstation"
	@echo ""

.PHONY: setup-git-remote
setup-git-remote:
	@echo "Setting up git repository on Batocera..."
	@ssh $(BATOCERA_USER)@$(BATOCERA_HOST) "cd $(BATOCERA_PATH) && git init && git remote add origin https://github.com/yourusername/anki-viewer.git || true"
	@echo "Done. Don't forget to update the remote URL!"

# Info targets
.PHONY: info
info:
	@echo "========================================"
	@echo "  Anki Viewer - Project Info"
	@echo "========================================"
	@echo ""
	@echo "Local paths:"
	@echo "  Project: $(CURDIR)"
	@echo "  App:     $(CURDIR)\share\roms\anki"
	@echo "  Tools:   $(CURDIR)\dev-tools"
	@echo ""
	@echo "Remote paths:"
	@echo "  Host:    $(BATOCERA_USER)@$(BATOCERA_HOST)"
	@echo "  App:     $(BATOCERA_PATH)"
	@echo ""
	@echo "Access:"
	@echo "  Web:     http://$(BATOCERA_HOST):5000"
	@echo "  SMB:     \\\\$(BATOCERA_HOST)\share\roms\anki"
	@echo "  SSH:     ssh $(BATOCERA_USER)@$(BATOCERA_HOST)"
	@echo ""
