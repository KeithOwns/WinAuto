#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables System Protection and Creates a System Restore Point in Windows 11
.DESCRIPTION
    Standardized for WinAuto. Ensures C: is protected and creates point.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "SYSTEM RESTORE POINT CREATOR"

# STEP 1: Enable Protection
Write-LeftAligned "$FGWhite$Char_HeavyMinus STEP 1: Enabling System Protection$Reset"
try {
    Write-LeftAligned "  $FGYellow Attempting to enable System Protection on C:\...$Reset"
    Enable-ComputerRestore -Drive "C:\"
    Write-LeftAligned "  $FGGreen$Char_HeavyCheck Successfully enabled System Protection.$Reset"
    Start-Sleep -Seconds 1
} catch {
    Write-LeftAligned "  $FGGray  (System Protection may already be enabled or managed by policy)$Reset"
}

# STEP 2: Create Point
Write-Host ""
Write-LeftAligned "$FGWhite$Char_HeavyMinus STEP 2: Creating Restore Point$Reset"
$description = "WinAuto Manual Point - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-LeftAligned "  $FGYellow Description: $description$Reset"

try {
    Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Host ""
    Write-LeftAligned "$FGGreen$Char_BallotCheck Restore Point created successfully!$Reset"
} catch {
    Write-Host ""
    Write-LeftAligned "$FGRed$Char_RedCross Failed to create restore point.$Reset"
    Write-LeftAligned "  Details: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






