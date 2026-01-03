#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Disables or Enables Potentially Unwanted App (PUA) Protection at Device Level.
.DESCRIPTION
    Standardized for WinAuto. Uses Group Policy to configure PUA protection.
.PARAMETER Undo
    Reverses the setting (Enables PUA Protection).
#>

[CmdletBinding()]
param(
    [switch]$Undo,
    [switch]$Rollback
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

#region Logic Configuration
$Script:LogFile = "$env:TEMP\PUAProtection-W11-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Script:BackupFile = "$env:TEMP\PUAProtection-Backup-W11-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$Script:GroupPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$Script:GroupPolicyValue = "PUAProtection"

$targetValue = if ($Undo) { 1 } else { 0 }
$actionText = if ($Undo) { "ENABLE" } else { "DISABLE" }
$statusText = if ($Undo) { "ENABLED" } else { "DISABLED" }
#endregion

#region Functions

function Write-Step {
    param([string]$Message, [ValidateSet('Info','Warning','Error','Success')]$Level = 'Info')
    $color = switch ($Level) { 'Info'{'Cyan'}; 'Warning'{'Yellow'}; 'Error'{'Red'}; 'Success'{'Green'} }
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] " -NoNewline -ForegroundColor Gray
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
    Add-Content -Path $Script:LogFile -Value "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] [$Level] $Message" -ErrorAction SilentlyContinue
}

function Backup-CurrentState {
    Write-Step "Creating backup of current PUA state..."
    $backup = @{ Timestamp = Get-Date; GroupPolicy = $null; MpPreference = $null }
    try {
        if (Test-Path $Script:GroupPolicyPath) {
            $backup.GroupPolicy = (Get-ItemProperty -Path $Script:GroupPolicyPath -Name $Script:GroupPolicyValue -ErrorAction SilentlyContinue).$Script:GroupPolicyValue
        }
        $backup.MpPreference = (Get-MpPreference).PUAProtection
    } catch {}
    $backup | ConvertTo-Json | Out-File -FilePath $Script:BackupFile -Force
    Write-Step "Backup saved to: $Script:BackupFile" -Level Success
}

function Restore-PUAState {
    param([string]$Path)
    if (-not (Test-Path $Path)) { Write-Step "Backup not found." -Level Error; return $false }
    try {
        $b = Get-Content $Path -Raw | ConvertFrom-Json
        if ($null -ne $b.GroupPolicy) {
            Set-ItemProperty -Path $Script:GroupPolicyPath -Name $Script:GroupPolicyValue -Value $b.GroupPolicy -Type DWord -Force
        } else {
            Remove-ItemProperty -Path $Script:GroupPolicyPath -Name $Script:GroupPolicyValue -ErrorAction SilentlyContinue
        }
        $prefValue = if($b.MpPreference -eq 1){'Enabled'}else{'Disabled'}
        Set-MpPreference -PUAProtection $prefValue -ErrorAction SilentlyContinue
        & gpupdate /force | Out-Null
        return $true
    } catch { return $false }
}

#endregion

# --- MAIN ---

Write-Header "$actionText PUA PROTECTION"

if ($Rollback) {
    Write-Step "Searching for backups..." -Level Warning
    $latest = Get-ChildItem $env:TEMP -Filter "PUAProtection-Backup-W11-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        if (Restore-PUAState -Path $latest.FullName) { Write-Step "Rollback successful." -Level Success }
        else { Write-Step "Rollback failed." -Level Error }
    } else { Write-Step "No backup found." -Level Error }
    Start-Sleep -Seconds 1
    exit
}

# Status Check
$gp = (Get-ItemProperty -Path $Script:GroupPolicyPath -Name $Script:GroupPolicyValue -ErrorAction SilentlyContinue).$Script:GroupPolicyValue
if ($gp -eq $targetValue) {
    Write-Step "PUA Protection is already $statusText via Group Policy." -Level Success
    Start-Sleep -Seconds 1
    exit
}

# Warning
if (-not $Undo) {
    Write-Boundary $FGRed
    Write-Centered "$Bold$FGRed SECURITY WARNING $Reset"
    Write-LeftAligned "Disabling PUA Protection lowers device security."
    Write-Boundary $FGRed
    Write-Host ""
}

Backup-CurrentState

# Configure
Write-Step "Applying Group Policy (PUAProtection = $targetValue)..."
try {
    if (-not (Test-Path $Script:GroupPolicyPath)) { New-Item -Path $Script:GroupPolicyPath -Force | Out-Null }
    Set-ItemProperty -Path $Script:GroupPolicyPath -Name $Script:GroupPolicyValue -Value $targetValue -Type DWord -Force
    
    $pref = if ($targetValue -eq 1) { 'Enabled' } else { 'Disabled' }
    Set-MpPreference -PUAProtection $pref -ErrorAction SilentlyContinue
    
    Write-Step "Policy applied. Forcing Group Policy update..."
    & gpupdate /force | Out-Null
    Write-Step "Operation complete. PUA Protection is $statusText." -Level Success
} catch {
    Write-Step "Failed to apply policy: $($_.Exception.Message)" -Level Error
}

Write-Host ""
Write-Boundary $FGDarkGray
Write-Centered "RESTART RECOMMENDED"
Write-Boundary $FGDarkGray

Start-Sleep -Seconds 1
Write-Host ""






