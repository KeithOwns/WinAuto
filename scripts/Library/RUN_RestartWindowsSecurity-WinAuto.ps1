#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Restarts the Windows Security application.
.DESCRIPTION
    Standardized for WinAuto. Stops SecHealthUI and SecurityHealthSystray, then restarts.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$NoRestart
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

#region Functions

function Write-Step {
    param([string]$Message, [ValidateSet('Info','Success','Warning','Error')]$Level = 'Info')
    $color = switch ($Level) { 'Info'{'Cyan'}; 'Success'{'Green'}; 'Warning'{'Yellow'}; 'Error'{'Red'} }
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor Gray
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

function Stop-SecurityProcesses {
    $procs = @('SecurityHealthSystray', 'SecHealthUI')
    foreach ($p in $procs) {
        try {
            $existing = Get-Process -Name $p -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Step "Stopping: $p..."
                $existing | Stop-Process -Force -ErrorAction Stop
                Write-Step "Stopped $p." -Level Success
            }
        } catch { Write-Step "Failed to stop $p." -Level Warning }
    }
}

#endregion

# --- MAIN ---

Write-Header "RESTART WINDOWS SECURITY"

try {
    Stop-SecurityProcesses
    
    if (-not $NoRestart) {
        Write-Host ""
        Write-Step "Starting Windows Security app..."
        Start-Process "windowsdefender:"
        Start-Sleep -Seconds 2
        Write-Step "Restart command issued." -Level Success
    } else {
        Write-Step "NoRestart flag present. Skipping launch." -Level Info
    }

} catch {
    Write-Host ""
    Write-Step "Unexpected error: $($_.Exception.Message)" -Level Error
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






