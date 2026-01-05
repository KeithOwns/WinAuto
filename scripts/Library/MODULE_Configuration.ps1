#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Module: Core Windows Configuration & Hardening
.DESCRIPTION
    Fully automated core configuration. Non-blocking.
#>

param([switch]$SmartRun, [switch]$EnhancedSecurity)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
. "$PSScriptRoot\WinAuto_Functions.ps1"
$Global:WinAutoCompactMode = $true

# --- LOGGING ---
try { Start-Transcript -Path $Global:WinAutoLogPath -Append -ErrorAction SilentlyContinue | Out-Null } catch {}

# --- MAIN EXECUTION ---
Write-Header "WINDOWS CONFIGURATION PHASE"
$lastRun = Get-WinAutoLastRun -Module "Configuration"
Write-LeftAligned "$FGGray Last Run: $FGWhite$lastRun$Reset"

if ($SmartRun -and $lastRun -ne "Never") {
    $lastDate = Get-Date $lastRun
    if ((Get-Date) -lt $lastDate.AddDays(30)) {
        Write-Host ""
        Write-LeftAligned "$FGGreen$Char_CheckMark Configuration is up to date (Run < 30 days ago). Skipping...$Reset"
        Write-Boundary
        Write-Footer
        try { if ($null -ne (Get-Variable -Name "Transcript" -ErrorAction SilentlyContinue)) { Stop-Transcript | Out-Null } } catch {}
        exit
    }
}

Write-Boundary

# Pre-checks
$av = Get-ThirdPartyAV
$tp = Test-TamperProtection

# 1. SECURITY HARDENING
$secScripts = @(
    "SET_EnableRealTimeProtection-WinAuto.ps1",
    "SET_EnablePUA-WinAuto.ps1",
    "SET_EnableMemoryIntegrity-WinAuto.ps1",
    "SET_EnableLSA-WinAuto.ps1",
    "SET_EnableKernelStackProtection-WinAuto.ps1",
    "SET_EnableSmartScreen-WinAuto.ps1",
    "SET_EnableMSstoreSmartScreen-WinAuto.ps1",
    "SET_EnablePhishingProtection-WinAuto.ps1",
    "SET_EnablePhishingProtectionMalicious-WinAuto.ps1",
    "SET_FirewallON-WinAuto.ps1"
)

foreach ($s in $secScripts) { 

    if ($s -eq "SET_EnableRealTimeProtection-WinAuto.ps1") {

        if ($null -ne $av) {

            Write-LeftAligned "$FGDarkYellow$Char_Warn Managed by $av. Skipping RTP Enable.$Reset"

            continue

        }

        if ($tp) {

            Write-LeftAligned "$FGDarkYellow$Char_Warn Tamper Protection is ON. Skipping RTP Enable.$Reset"

            continue

        }

    }

    & "$PSScriptRoot\$s" -Force 

}



# 2. UI OPTIMIZATION (Core Only)

& "$PSScriptRoot\SET_VisualEffectsPerformance-WinAuto.ps1"

# 3. WINDOWS UPDATE CONFIGURATION
Write-Host ""
Write-LeftAligned "$Bold$FGCyan WINDOWS UPDATE CONFIGURATION $Reset"
Write-Boundary $FGDarkCyan
Set-WUSettings -EnhancedSecurity:$EnhancedSecurity

# 4. DEBLOAT & PRIVACY (Standard)
Write-Host ""
Write-LeftAligned "$Bold$FGCyan DEBLOAT & PRIVACY OPTIMIZATION $Reset"
Write-Boundary $FGDarkCyan
& "$PSScriptRoot\C3_WindowsDebloat_CLEAN.ps1" -AutoRun

# 5. NETWORK SECURITY
if ($EnhancedSecurity) {
    Write-Host ""
    Write-LeftAligned "$Bold$FGCyan ENHANCED NETWORK SECURITY $Reset"
    Write-Boundary $FGDarkCyan
    & "$PSScriptRoot\C4_Network_FIXnSECURE.ps1" -AutoRun
} else {
    Write-Host ""
    Write-LeftAligned "$Bold$FGCyan RESTORING STANDARD NETWORK SETTINGS $Reset"
    Write-Boundary $FGDarkCyan
    & "$PSScriptRoot\C4_Network_FIXnSECURE.ps1" -AutoRun -Undo
}

Write-Boundary

Write-Centered "$FGGreen CONFIGURATION COMPLETE $Reset"
Set-WinAutoLastRun -Module "Configuration"

Write-Footer



try { if ($null -ne (Get-Variable -Name "Transcript" -ErrorAction SilentlyContinue)) { Stop-Transcript | Out-Null } } catch {}

