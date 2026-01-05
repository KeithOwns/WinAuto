#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 Privacy & Core UI Optimizer
.DESCRIPTION
    Standardized for WinAuto. Non-blocking core privacy hardening and UI tweaks.
    Includes File Explorer configurations, Classic Context Menu, Bloatware removal, and privacy settings.
.PARAMETER Undo
    Reverses the optimization (Restores default privacy, Explorer settings, and attempts to restore apps).
.PARAMETER AutoRun
    Runs without user intervention.
#>

param(
    [switch]$Undo,
    [switch]$AutoRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- LOGGING SETUP ---
. "$PSScriptRoot\MODULE_Logging.ps1"
Init-Logging


# --- BLOATWARE LISTS ---
$ThirdPartyBloat = @(
    "*Spotify*", "*Disney*", "*Netflix*", "*Instagram*", "*TikTok*", "*Facebook*", "*Twitter*", "*CandyCrush*", "*LinkedIn*", "*GamingApp*"
)
$MicrosoftBloat = @(
    "*BingNews*", "*BingWeather*", "*GetHelp*", "*GetStarted*", "*Microsoft365Hub*", "*SolitaireCollection*", "*Todos*", "*FeedbackHub*", "*YourPhone*", "*Cortana*"
)

# --- FUNCTIONS ---

function Configure-Privacy {
    $action = if ($Undo) { "Restoring" } else { "Hardening" }
    Write-Host ""
    Write-LeftAligned "$Bold$FGWhite$Char_HeavyMinus $action Privacy Settings$Reset"
    
    $advVal = if ($Undo) { 1 } else { 0 }
    $telemetryVal = if ($Undo) { 3 } else { 0 } # 3 = Full (default), 0 = Security
    $cloudVal = if ($Undo) { 0 } else { 1 }

    try {
        if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) { New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force | Out-Null }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value $advVal -Type DWord -Force
        
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value $telemetryVal -Type DWord -Force
        
        if (-not (Test-Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null }
        Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value $cloudVal -Type DWord -Force
        
        $status = if ($Undo) { "Restored" } else { "Applied" }
        Write-LeftAligned "$FGGreen$Char_CheckMark Privacy settings $status.$Reset"
    } catch { Write-LeftAligned "$FGRed$Char_FailureX Privacy settings error: $($_.Exception.Message)$Reset" }
}

function Configure-Explorer {
    $action = if ($Undo) { "Restoring" } else { "Optimizing" }
    Write-Host ""
    Write-LeftAligned "$Bold$FGWhite$Char_HeavyMinus $action File Explorer Settings$Reset"

    # Show File Extensions: 0=Show, 1=Hide
    $hideExtVal = if ($Undo) { 1 } else { 0 }
    # Show Hidden Files: 1=Show, 2=Hide
    $hiddenVal = if ($Undo) { 2 } else { 1 }
    # Show System Files (SuperHidden): 1=Show, 0=Hide
    $superHiddenVal = if ($Undo) { 0 } else { 1 }

    try {
        $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        
        Set-ItemProperty -Path $path -Name "HideFileExt" -Value $hideExtVal -Type DWord -Force
        Set-ItemProperty -Path $path -Name "Hidden" -Value $hiddenVal -Type DWord -Force
        Set-ItemProperty -Path $path -Name "ShowSuperHidden" -Value $superHiddenVal -Type DWord -Force
        
        $status = if ($Undo) { "Restored" } else { "Optimized" }
        Write-LeftAligned "$FGGreen$Char_CheckMark Explorer settings $status.$Reset"
    } catch { Write-LeftAligned "$FGRed$Char_FailureX Explorer settings error: $($_.Exception.Message)$Reset" }
}

function Configure-ContextMenu {
    $action = if ($Undo) { "Restoring Standard" } else { "Enabling Classic" }
    Write-Host ""
    Write-LeftAligned "$Bold$FGWhite$Char_HeavyMinus $action Context Menu$Reset"

    try {
        $key = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
        
        if ($Undo) {
            if (Test-Path $key) {
                Remove-Item -Path $key -Recurse -Force -ErrorAction SilentlyContinue
            }
            Write-LeftAligned "$FGGreen$Char_CheckMark Standard context menu restored.$Reset"
        } else {
            if (-not (Test-Path "$key\InprocServer32")) { New-Item -Path "$key\InprocServer32" -Force | Out-Null }
            Set-ItemProperty -Path "$key\InprocServer32" -Name "(default)" -Value "" -Force
            Write-LeftAligned "$FGGreen$Char_CheckMark Classic context menu enabled.$Reset"
        }
    } catch { Write-LeftAligned "$FGRed$Char_FailureX Context menu error: $($_.Exception.Message)$Reset" }
}

function Remove-Bloatware {
    Write-Host ""
    Write-LeftAligned "$Bold$FGWhite$Char_HeavyMinus Managing Bloatware Apps$Reset"
    
    try {
        if ($Undo) {
            Write-LeftAligned "$FGYellow Attempting to restore default apps...$Reset"
            Get-AppxPackage -AllUsers | ForEach-Object {
                if ($_.InstallLocation -and (Test-Path "$($_.InstallLocation)\AppXManifest.xml")) {
                    Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
                }
            }
            Write-LeftAligned "$FGGreen$Char_CheckMark Restoration process complete.$Reset"
        } else {
            Write-LeftAligned "$FGYellow Scanning and removing bloatware apps...$Reset"
            $list = $ThirdPartyBloat + $MicrosoftBloat
            $found = 0
            foreach ($pattern in $list) {
                $app = Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue
                if ($app) {
                    Write-LeftAligned "  Removing: $($app.Name)"
                    $app | Remove-AppxPackage -ErrorAction SilentlyContinue
                    $found++
                }
            }
            Write-LeftAligned "$FGGreen$Char_CheckMark Removed $found bloatware apps.$Reset"
        }
    } catch { Write-LeftAligned "$FGRed$Char_FailureX Bloatware error: $($_.Exception.Message)$Reset" }
}

# --- MAIN EXECUTION ---
$headerTitle = if ($Undo) { "DEBLOAT & PRIVACY RESTORE" } else { "PRIVACY & UI OPTIMIZATION" }
Write-Header $headerTitle

Configure-Privacy
Configure-Explorer
Configure-ContextMenu
Remove-Bloatware

# Restart explorer to apply changes
if (-not $AutoRun) {
    Write-Host ""
    Write-LeftAligned "$FGYellow Restarting File Explorer to apply UI changes...$Reset"
    Stop-Process -Name explorer -Force
}

# Report
Get-LogReport

Write-Host ""
Write-Boundary
$footerMsg = if ($Undo) { "RESTORATION COMPLETE" } else { "OPTIMIZATION COMPLETE" }
Write-Centered "$FGGreen $footerMsg $Reset"
Write-Boundary
Write-Host ""
