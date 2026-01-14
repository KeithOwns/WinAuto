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
if ($null -eq $av) {
    & "$PSScriptRoot\SET_Enable-VirusThreatProtection.ps1"
}

$secScripts = @(
    "SET_EnableRealTimeProtection-WinAuto.ps1",
    "SET_Enable-FirewallNetworkProtection.ps1",
    "SET_EnablePUA-WinAuto.ps1",
    "SET_EnableMemoryIntegrity-WinAuto.ps1",
    "SET_EnableLSA-WinAuto.ps1",
    "SET_Enable-KernelModeHardwareStackProtection.ps1",
    "SET_EnableSmartScreen-WinAuto.ps1",
    "SET_EnableMSstoreSmartScreen-WinAuto.ps1",
    "SET_EnablePhishingProtection-WinAuto.ps1",
    "SET_EnablePhishingProtectionMalicious-WinAuto.ps1",
    "SET_FirewallON-WinAuto.ps1"
)

foreach ($s in $secScripts) { 

    if ($s -eq "SET_EnableRealTimeProtection-WinAuto.ps1" -or $s -eq "SET_Enable-FirewallNetworkProtection.ps1") {

        if ($null -ne $av) {

            Write-LeftAligned "$FGDarkYellow$Char_Warn Managed by $av. Skipping $($s -replace '-WinAuto.ps1','').$Reset"

            continue

        }

        if ($tp) {

            Write-LeftAligned "$FGDarkYellow$Char_Warn Tamper Protection is ON. Skipping $($s -replace '-WinAuto.ps1','').$Reset"

            continue

        }

    }

    & "$PSScriptRoot\$s" -Force 

}



# 2. UI OPTIMIZATION (Core Only)

& "$PSScriptRoot\SET_VisualEffectsPerformance-WinAuto.ps1"
& "$PSScriptRoot\SET_TaskbarDefaults-WinAuto.ps1"
& "$PSScriptRoot\SET_PowerPlanHigh-WinAuto.ps1"

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

# 5. HIDE LOCAL ADMINISTRATOR ACCOUNTS (Default - runs before network/security)
Write-Host ""
Write-LeftAligned "$Bold$FGCyan HIDING LOCAL ADMINISTRATOR ACCOUNTS $Reset"
Write-Boundary $FGDarkCyan

try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
    
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-LeftAligned "$FGGreen$Char_CheckMark Created registry path for user list.$Reset"
    }
    
    # Hide Administrator account
    Set-ItemProperty -Path $regPath -Name "Administrator" -Value 0 -Type DWord -Force
    Write-LeftAligned "$FGGreen$Char_CheckMark Administrator account hidden from login screen.$Reset"
    
    # Hide admin account (if it exists)
    $adminUser = Get-LocalUser -Name "admin" -ErrorAction SilentlyContinue
    if ($adminUser) {
        Set-ItemProperty -Path $regPath -Name "admin" -Value 0 -Type DWord -Force
        Write-LeftAligned "$FGGreen$Char_CheckMark admin account hidden from login screen.$Reset"
    } else {
        Write-LeftAligned "$FGDarkGray$Char_Info admin account not found, skipping.$Reset"
    }
    
} catch {
    Write-LeftAligned "$FGRed$Char_Warn Failed to hide admin accounts: $_$Reset"
}

# 6. NETWORK & POWERSHELL SECURITY
if ($EnhancedSecurity) {
    Write-Host ""
    Write-LeftAligned "$Bold$FGCyan ENHANCED NETWORK & POWERSHELL SECURITY $Reset"
    Write-Boundary $FGDarkCyan
    & "$PSScriptRoot\C4_Network_FIXnSECURE.ps1" -AutoRun
    & "$PSScriptRoot\SET_PowerShellSecurity-WinAuto.ps1" -Force
} else {
    Write-Host ""
    Write-LeftAligned "$Bold$FGCyan RESTORING STANDARD NETWORK SETTINGS $Reset"
    Write-Boundary $FGDarkCyan
    & "$PSScriptRoot\C4_Network_FIXnSECURE.ps1" -AutoRun -Undo
}
Write-Host ""
Write-LeftAligned "$Bold$FGCyan HIDING LOCAL ADMINISTRATOR ACCOUNTS $Reset"
Write-Boundary $FGDarkCyan

try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
    
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-LeftAligned "$FGGreen$Char_CheckMark Created registry path for user list.$Reset"
    }
    
    # Hide Administrator account
    Set-ItemProperty -Path $regPath -Name "Administrator" -Value 0 -Type DWord -Force
    Write-LeftAligned "$FGGreen$Char_CheckMark Administrator account hidden from login screen.$Reset"
    
    # Hide admin account (if it exists)
    $adminUser = Get-LocalUser -Name "admin" -ErrorAction SilentlyContinue
    if ($adminUser) {
        Set-ItemProperty -Path $regPath -Name "admin" -Value 0 -Type DWord -Force
        Write-LeftAligned "$FGGreen$Char_CheckMark admin account hidden from login screen.$Reset"
    } else {
        Write-LeftAligned "$FGDarkGray$Char_Info admin account not found, skipping.$Reset"
    }
    
} catch {
    Write-LeftAligned "$FGRed$Char_Warn Failed to hide admin accounts: $_$Reset"
}

# Restart Explorer to apply UI changes
if (-not $EnhancedSecurity) {
    # If EnhancedSecurity is ON, Debloat module handles restart. If OFF, we must do it here.
    # Actually, let's just force it to be safe, Debloat might have run earlier or not at all if skipped.
    # Wait, the main WinAuto script structure is: Config -> Maintenance.
    # Debloat is called in Step 4.
    # Step 4 calls `C3_WindowsDebloat_CLEAN.ps1`.
    # Let's check `C3_WindowsDebloat_CLEAN.ps1`. It usually restarts explorer.
    # But if standard run, step 4 runs.
    # Wait, Step 4 runs `C3_WindowsDebloat_CLEAN.ps1 -AutoRun`.
    # Does `C3` restart explorer?
    
    # To be safe and consistent with Standalone, we'll add it here.
    Write-Host ""
    Write-LeftAligned "Restarting Explorer to apply UI settings..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

Write-Boundary

Write-Centered "$FGGreen CONFIGURATION COMPLETE $Reset"
Set-WinAutoLastRun -Module "Configuration"

Write-Footer



try { if ($null -ne (Get-Variable -Name "Transcript" -ErrorAction SilentlyContinue)) { Stop-Transcript | Out-Null } } catch {}
