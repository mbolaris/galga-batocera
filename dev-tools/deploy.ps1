# Deploy Anki Viewer to Batocera
# Syncs files from the local share/roms/anki to the Batocera device
#
# Usage:
#   .\deploy.ps1                    # Deploy to default host
#   .\deploy.ps1 -Host 192.168.1.53  # Deploy to specific host
#   .\deploy.ps1 -Restart            # Deploy and restart Flask

param(
    [string]$Host = "192.168.1.53",
    [string]$User = "root",
    [switch]$Restart,
    [switch]$Update,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Deploy Anki Viewer to Batocera

Usage:
  .\deploy.ps1 [options]

Options:
  -Host <ip>       Batocera IP address (default: 192.168.1.53)
  -User <user>     SSH user (default: root)
  -Restart         Restart Flask after deploying
  -Update          Run dev-update.sh after deploying (pulls git, updates deps)
  -Help            Show this help message

Examples:
  .\deploy.ps1                           # Quick deploy
  .\deploy.ps1 -Restart                  # Deploy and restart
  .\deploy.ps1 -Update                   # Deploy and update (git pull, deps)
  .\deploy.ps1 -Host 192.168.1.100       # Deploy to different host
"@
    exit 0
}

$LocalPath = "c:\shared\bolaris\galga-batocera\share\roms\anki"
$RemotePath = "/userdata/roms/anki"

Write-Host "========================================"
Write-Host "  Anki Viewer - Deploy to Batocera"
Write-Host "========================================"
Write-Host ""
Write-Host "Local path:  $LocalPath"
Write-Host "Remote host: $User@$Host"
Write-Host "Remote path: $RemotePath"
Write-Host ""

# Check if local path exists
if (-not (Test-Path $LocalPath)) {
    Write-Host "ERROR: Local path not found: $LocalPath" -ForegroundColor Red
    exit 1
}

# Check if ssh/scp are available
if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: ssh command not found. Please install OpenSSH." -ForegroundColor Red
    exit 1
}

# Test SSH connection
Write-Host "Testing SSH connection..." -ForegroundColor Yellow
$testResult = ssh -o ConnectTimeout=5 -o BatchMode=yes "$User@$Host" "echo ok" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Cannot connect to $Host" -ForegroundColor Red
    Write-Host "Make sure:"
    Write-Host "  1. Batocera is powered on"
    Write-Host "  2. SSH is enabled"
    Write-Host "  3. You have SSH keys set up (or use password auth)"
    exit 1
}
Write-Host "✓ Connected" -ForegroundColor Green
Write-Host ""

# Create remote directory if needed
Write-Host "Ensuring remote directory exists..." -ForegroundColor Yellow
ssh "$User@$Host" "mkdir -p $RemotePath"
Write-Host "✓ Directory ready" -ForegroundColor Green
Write-Host ""

# Sync files using SCP
Write-Host "Deploying files..." -ForegroundColor Yellow
Write-Host ""

# Get all files to deploy (excluding venv, __pycache__, etc.)
$filesToDeploy = Get-ChildItem -Path $LocalPath -Recurse -File | Where-Object {
    $_.FullName -notmatch 'venv[\\/]' -and
    $_.FullName -notmatch '__pycache__[\\/]' -and
    $_.FullName -notmatch '\.pyc$' -and
    $_.FullName -notmatch '\.log$' -and
    $_.FullName -notmatch '\.pid$' -and
    $_.Name -ne '.DS_Store'
}

$totalFiles = $filesToDeploy.Count
$currentFile = 0

foreach ($file in $filesToDeploy) {
    $currentFile++
    $relativePath = $file.FullName.Substring($LocalPath.Length).TrimStart('\', '/')
    $relativePathUnix = $relativePath -replace '\\', '/'
    $remoteDirPath = Split-Path -Path "$RemotePath/$relativePathUnix" -Parent

    # Ensure remote directory exists
    ssh "$User@$Host" "mkdir -p '$remoteDirPath'" 2>$null

    # Copy file
    $percent = [math]::Round(($currentFile / $totalFiles) * 100)
    Write-Host "[$percent%] $relativePathUnix"
    scp -q "$($file.FullName)" "$User@${Host}:$RemotePath/$relativePathUnix"
}

Write-Host ""
Write-Host "✓ All files deployed ($totalFiles files)" -ForegroundColor Green
Write-Host ""

# Fix permissions
Write-Host "Setting permissions..." -ForegroundColor Yellow
ssh "$User@$Host" "chmod +x $RemotePath/*.sh"
Write-Host "✓ Permissions set" -ForegroundColor Green
Write-Host ""

# Optional: Run dev-update.sh
if ($Update) {
    Write-Host "Running dev-update.sh..." -ForegroundColor Yellow
    ssh "$User@$Host" "cd $RemotePath && ./dev-update.sh --skip-git"
    Write-Host "✓ Update complete" -ForegroundColor Green
    Write-Host ""
}
# Optional: Restart Flask
elseif ($Restart) {
    Write-Host "Restarting Flask..." -ForegroundColor Yellow
    ssh "$User@$Host" "cd $RemotePath && ./dev-restart.sh"
    Write-Host "✓ Flask restarted" -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================"
Write-Host "  Deployment Complete!"
Write-Host "========================================"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  - Access app: http://${Host}:5000"
Write-Host "  - View logs:  ssh $User@$Host 'tail -f $RemotePath/flask.log'"
Write-Host "  - Restart:    .\deploy.ps1 -Restart"
Write-Host "  - Update:     .\deploy.ps1 -Update"
Write-Host ""
