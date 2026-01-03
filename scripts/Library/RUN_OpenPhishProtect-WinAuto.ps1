#Requires -RunAsAdministrator
<#
.SYNOPSIS
  A stand-alone script to open Phishing Protection settings.
.DESCRIPTION
  Standardized for WinAuto. Opens Windows Security > App & browser control.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

#region Functions

function Open-PhishingSettings {
    try {
        Start-Process -FilePath "windowsdefender://appbrowser"
        Start-Sleep -Seconds 2
        $wshell = New-Object -ComObject WScript.Shell
        if ($wshell.AppActivate("Windows Security")) {
            Start-Sleep -Milliseconds 500
            $wshell.SendKeys("{TAB 2}")
        }
        return $true
    } catch { return $false }
}

#endregion

# --- MAIN ---

Write-Header "PHISHING PROTECTION UI"

Write-LeftAligned "$FGYellow Note: Phishing protection for Edge must be manually set!$Reset"
Write-Host ""

$res = Start-Sleep -Seconds 1

if ($res.VirtualKeyCode -eq 13) {
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Opening Windows Security > App & browser control...$Reset"
    if (-not (Open-PhishingSettings)) {
        Write-LeftAligned "$FGRed$Char_RedCross Failed to open settings automatically.$Reset"
    }
} else {
    Write-LeftAligned "$FGGray  - Skipping Windows phishing protection setup.$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






