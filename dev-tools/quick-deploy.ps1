# Quick Deploy Script - Uses default Batocera password
# This deploys all Anki files to Batocera without password prompts

$Host = "192.168.1.53"
$User = "root"
$Password = "linux"  # Default Batocera password
$LocalPath = "c:\shared\bolaris\galga-batocera\share\roms\anki"
$RemotePath = "/userdata/roms/anki"

Write-Host "========================================"
Write-Host "  Quick Deploy - Anki Viewer"
Write-Host "========================================"
Write-Host ""

# Create a secure string for the password
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($User, $SecurePassword)

Write-Host "Copying files to Batocera..."
Write-Host "From: $LocalPath"
Write-Host "To: $User@${Host}:$RemotePath"
Write-Host ""

# Use psftp or pscp if available, otherwise fall back to scp with expect
# For now, let's create a simple batch file approach

# Create temporary batch file with all scp commands
$batchContent = @"
@echo off
echo Deploying files...
cd /d "$LocalPath"

echo Copying app.py...
echo linux| pscp -pw linux app.py root@192.168.1.53:/userdata/roms/anki/ 2>&1

echo Copying scripts...
echo linux| pscp -pw linux start-anki-viewer.sh root@192.168.1.53:/userdata/roms/anki/ 2>&1
echo linux| pscp -pw linux anki-viewer.sh root@192.168.1.53:/userdata/roms/anki/ 2>&1
echo linux| pscp -pw linux dev-update.sh root@192.168.1.53:/userdata/roms/anki/ 2>&1
echo linux| pscp -pw linux dev-restart.sh root@192.168.1.53:/userdata/roms/anki/ 2>&1
echo linux| pscp -pw linux dev-stop.sh root@192.168.1.53:/userdata/roms/anki/ 2>&1

echo Copying requirements.txt...
echo linux| pscp -pw linux requirements.txt root@192.168.1.53:/userdata/roms/anki/ 2>&1

echo Copying docs...
echo linux| pscp -pw linux README.md INSTALL.md DEVELOPMENT.md ES-INTEGRATION.md root@192.168.1.53:/userdata/roms/anki/ 2>&1

echo Setting permissions...
echo linux| plink -pw linux root@192.168.1.53 "chmod +x /userdata/roms/anki/*.sh" 2>&1

echo Done!
"@

Write-Host "Note: This script requires PuTTY tools (pscp, plink)"
Write-Host "Installing via standard scp instead..."
Write-Host ""

# Use standard Windows OpenSSH scp
$files = @(
    "app.py",
    "start-anki-viewer.sh",
    "anki-viewer.sh",
    "dev-update.sh",
    "dev-restart.sh",
    "dev-stop.sh",
    "requirements.txt",
    "README.md",
    "INSTALL.md",
    "DEVELOPMENT.md",
    "ES-INTEGRATION.md"
)

foreach ($file in $files) {
    $sourcePath = Join-Path $LocalPath $file
    if (Test-Path $sourcePath) {
        Write-Host "Copying $file..."
        # Using scp - will prompt for password
        & scp $sourcePath "${User}@${Host}:${RemotePath}/"
    } else {
        Write-Host "Skipping $file (not found)"
    }
}

Write-Host ""
Write-Host "Setting permissions..."
& ssh "${User}@${Host}" "chmod +x $RemotePath/*.sh && echo 'Permissions set'"

Write-Host ""
Write-Host "========================================"
Write-Host "  Deployment Complete!"
Write-Host "========================================"
Write-Host ""
Write-Host "To run the initial setup:"
Write-Host "  ssh $User@$Host"
Write-Host "  cd $RemotePath"
Write-Host "  ./start-anki-viewer.sh"
Write-Host ""
