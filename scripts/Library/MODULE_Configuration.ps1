#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Module: Core Windows Configuration & Hardening
.DESCRIPTION
    Fully automated core configuration. Non-blocking.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
$Global:WinAutoCompactMode = $true

# --- LOGGING ---
try { Start-Transcript -Path $Global:WinAutoLogPath -Append -ErrorAction SilentlyContinue | Out-Null } catch {}

# --- DETECTION HELPERS ---

function Get-ThirdPartyAV {
    try {
        $av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
        foreach ($a in $av) { if ($a.displayName -notmatch "Defender|Windows Security") { return $a.displayName } }
    } catch {}
    return $null
}

function Test-TamperProtection {
    try {
        $tp = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -ErrorAction SilentlyContinue).TamperProtection
        return ($tp -eq 5 -or $tp -eq 1) # 5 = Enabled/Managed
    } catch { return $false }
}

# --- MAIN EXECUTION ---
Write-Header "WINDOWS CONFIGURATION PHASE"
$lastRun = Get-WinAutoLastRun -Module "Configuration"
Write-LeftAligned "$FGGray Last Run: $FGWhite$lastRun$Reset"
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



Write-Boundary

Write-Centered "$FGGreen CONFIGURATION COMPLETE $Reset"
Set-WinAutoLastRun -Module "Configuration"

Write-Footer



try { if ($null -ne (Get-Variable -Name "Transcript" -ErrorAction SilentlyContinue)) { Stop-Transcript | Out-Null } } catch {}

