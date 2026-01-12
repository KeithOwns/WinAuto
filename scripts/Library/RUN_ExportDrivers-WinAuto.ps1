#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Driver Export Utility
.DESCRIPTION
    Exports all third-party drivers from the driver store to a backup folder.
    Useful before reinstalling Windows or migrating to a new PC.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "DRIVER EXPORT"

$DateStr = Get-Date -Format "yyyy-MM-dd"
$BackupPath = "C:\Drivers_Backup_$DateStr"

Write-Host ""
Write-LeftAligned "$FGYellow Starting Driver Export...$Reset"
Write-LeftAligned "Target: $BackupPath"
Write-Host ""

if (-not (Test-Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
}

try {
    # Export-WindowsDriver -Online -Destination
    # Capture output to avoid screen clutter, but show progress
    Write-LeftAligned "$FGGray Exporting third-party drivers... This may take a minute.$Reset"
    
    $drivers = Export-WindowsDriver -Online -Destination $BackupPath -ErrorAction Stop
    
    $count = $drivers.Count
    Write-Host ""
    Write-LeftAligned "$FGGreen$Char_BallotCheck Success! Exported $count drivers.$Reset"
    Write-LeftAligned "Location: $BackupPath"
    
    # Optional: Offer to open folder
    Write-Host ""
    $choice = Read-Host "  Open backup folder? (Y/N)"
    if ($choice -match '^[Yy]') {
        Invoke-Item $BackupPath
    }

} catch {
    Write-Host ""
    Write-LeftAligned "$FGRed$Char_Warn Error exporting drivers: $($_.Exception.Message)$Reset"
}

Write-Host ""
$null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
Write-Host ""





