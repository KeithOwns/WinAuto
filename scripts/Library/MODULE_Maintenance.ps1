#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Module: Full Windows Maintenance & Optimization
.DESCRIPTION
    Fully automated maintenance of Windows 11. Non-blocking.
#>

param([switch]$SmartRun, [switch]$EnhancedSecurity)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
$Global:WinAutoCompactMode = $true

# --- ERROR LOGGING SETUP ---
$Global:WinAutoErrorLogPath = "$env:WinAutoLogDir\Maintenance_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
if (-not (Test-Path $env:WinAutoLogDir)) { New-Item -Path $env:WinAutoLogDir -ItemType Directory -Force | Out-Null }
"--- MAINTENANCE ERROR LOG START: $(Get-Date) ---" | Out-File -FilePath $Global:WinAutoErrorLogPath -Encoding UTF8 -Force

# Global Error Trap
Trap {
    Write-Log -Message "Unhandled Script Error: $($_.Exception.Message)" -Level ERROR
    Continue
}

# --- HELPER: Smart Check ---
function Test-RunNeeded {
    param($Key, $Days)
    if (-not $SmartRun) { return $true }
    $last = Get-WinAutoLastRun -Module $Key
    if ($last -eq "Never") { return $true }
    $date = Get-Date $last
    if ((Get-Date) -gt $date.AddDays($Days)) { return $true }
    
    Write-LeftAligned "$FGGreen$Char_CheckMark Skipping $Key (Run < $Days days ago).$Reset"
    return $false
}

# --- MAIN EXECUTION ---
Write-Header "WINDOWS MAINTENANCE PHASE"
$lastRun = Get-WinAutoLastRun -Module "Maintenance"
Write-LeftAligned "$FGGray Last Run: $FGWhite$lastRun$Reset"
if ($SmartRun) { Write-LeftAligned "$FGCyan Smart Mode Active$Reset" }
Write-Boundary
& "$PSScriptRoot\CHECK_SystemPreCheck-WinAuto.ps1"

# 2. DISK HEALTH & CLEANUP
Write-Host ""
Write-LeftAligned "$Bold$FGCyan SYSTEM REPAIR & OPTIMIZATION $Reset"
Write-Boundary $FGDarkCyan

if (Test-RunNeeded -Key "Maintenance_SFC" -Days 30) {
    & "$PSScriptRoot\RUN_WindowsSFCRepair-WinAuto.ps1"
    Set-WinAutoLastRun -Module "Maintenance_SFC"
}

# 4. OPTIMIZATION
# Disk Optimization (7 Days)
if (Test-RunNeeded -Key "Maintenance_Disk" -Days 7) {
    & "$PSScriptRoot\RUN_OptimizeDisks-WinAuto.ps1"
    Set-WinAutoLastRun -Module "Maintenance_Disk"
}

# System Cleanup (7 Days)
if (Test-RunNeeded -Key "Maintenance_Cleanup" -Days 7) {
    & "$PSScriptRoot\RUN_SystemCleanup-WinAuto.ps1"
    Set-WinAutoLastRun -Module "Maintenance_Cleanup"
}

Write-Host ""
Write-Centered "$FGGreen MAINTENANCE COMPLETE $Reset"
Set-WinAutoLastRun -Module "Maintenance"
Write-Log "Maintenance Phase Complete. Errors (if any) logged to: $Global:WinAutoErrorLogPath" -Level INFO
$Global:WinAutoErrorLogPath = $null # Reset
Write-Footer

