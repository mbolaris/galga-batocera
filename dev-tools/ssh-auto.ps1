# Automated SSH helper for Batocera
# Uses stored password to avoid manual entry
#
# Usage:
#   .\ssh-auto.ps1 "command to run"
#   .\ssh-auto.ps1 "hostname"  # Just run hostname
#
# To use interactively:
#   .\ssh-auto.ps1 -Interactive

param(
    [Parameter(Position=0)]
    [string]$Command = "",

    [string]$Host = "192.168.1.53",
    [string]$User = "root",
    [switch]$Interactive
)

# Get password from environment variable
$password = [System.Environment]::GetEnvironmentVariable('BATOCERA_PASSWORD', [System.EnvironmentVariableTarget]::User)

if ([string]::IsNullOrEmpty($password)) {
    Write-Host "ERROR: BATOCERA_PASSWORD environment variable not set." -ForegroundColor Red
    Write-Host "Run this to set it:" -ForegroundColor Yellow
    Write-Host '  [System.Environment]::SetEnvironmentVariable("BATOCERA_PASSWORD", "your_password", [System.EnvironmentVariableTarget]::User)' -ForegroundColor Cyan
    exit 1
}

# Create a secure string from the password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($User, $securePassword)

if ($Interactive) {
    # Interactive shell
    Write-Host "Opening SSH shell to $User@$Host..." -ForegroundColor Yellow
    Write-Host "Note: Password will be auto-filled" -ForegroundColor Cyan
    Write-Host ""

    # Use plink if available for better interactive experience, otherwise fall back to ssh with expect
    $plinkPath = Get-Command plink -ErrorAction SilentlyContinue
    if ($plinkPath) {
        echo y | plink -ssh -l $User -pw $password $Host
    } else {
        # Fall back to ssh with password provided via environment
        $env:SSHPASS = $password
        ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no "$User@$Host"
    }
} else {
    # Execute command
    if ([string]::IsNullOrEmpty($Command)) {
        Write-Host "ERROR: No command specified." -ForegroundColor Red
        Write-Host "Usage: .\ssh-auto.ps1 'command' or .\ssh-auto.ps1 -Interactive" -ForegroundColor Yellow
        exit 1
    }

    # Create expect-like script for Git Bash's ssh
    $expectScript = @"
spawn ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no $User@$Host $Command
expect "password:"
send "$password\r"
expect eof
"@

    # Since expect might not be available, use PowerShell's native method
    # Create a temporary batch file that will provide password
    $tempBat = [System.IO.Path]::GetTempFileName() + ".bat"
    @"
@echo off
echo $password
"@ | Out-File -FilePath $tempBat -Encoding ASCII

    try {
        # Use the temp file as password input (this is a workaround)
        # Better approach: use Posh-SSH module if available
        $poshSSH = Get-Module -ListAvailable -Name Posh-SSH -ErrorAction SilentlyContinue
        if ($poshSSH) {
            Import-Module Posh-SSH
            $session = New-SSHSession -ComputerName $Host -Credential $credential -AcceptKey
            $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $Command
            Write-Host $result.Output
            Remove-SSHSession -SessionId $session.SessionId | Out-Null
        } else {
            # Fallback: write password to stdin (not ideal but works)
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "ssh"
            $psi.Arguments = "-o PreferredAuthentications=password -o PubkeyAuthentication=no $User@$Host `"$Command`""
            $psi.UseShellExecute = $false
            $psi.RedirectStandardInput = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $psi
            $process.Start() | Out-Null

            # Write password
            Start-Sleep -Milliseconds 500
            $process.StandardInput.WriteLine($password)
            $process.StandardInput.Close()

            # Read output
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            $process.WaitForExit()

            if (![string]::IsNullOrEmpty($stdout)) {
                Write-Host $stdout
            }
            if (![string]::IsNullOrEmpty($stderr) -and $process.ExitCode -ne 0) {
                Write-Host $stderr -ForegroundColor Red
            }
        }
    } finally {
        if (Test-Path $tempBat) {
            Remove-Item $tempBat -Force
        }
    }
}
