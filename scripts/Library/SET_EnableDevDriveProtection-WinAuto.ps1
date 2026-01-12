#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables 'Dev Drive protection' (Performance Mode) in Windows Security.

.DESCRIPTION
    This script enables Microsoft Defender Antivirus Performance Mode, which is 
    labeled as 'Dev Drive protection' in the Windows Security UI.
    
    Performance Mode improves performance for Dev Drives by performing 
    asynchronous scanning on those drives while maintaining protection.

.NOTES
    Requires Windows 11 and Administrator privileges.
    Microsoft Defender Antivirus must be the primary antivirus solution.
    
    Style/Formatting based on WinAuto standards.
#>

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    Exit 1
}

# --- STYLE SETUP ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ESC = [char]27
$Reset        = "$ESC[0m"
$Bold         = "$ESC[1m"
$FGWhite      = "$ESC[97m"
$FGGray       = "$ESC[37m"
$FGDarkGray   = "$ESC[90m"
$FGCyan       = "$ESC[96m"
$FGGreen      = "$ESC[92m"
$FGRed        = "$ESC[91m"
$FGYellow     = "$ESC[93m"
$FGDarkBlue   = "$ESC[34m"
$FGDarkGreen  = "$ESC[32m"
$FGDarkRed    = "$ESC[31m"
$FGDarkYellow = "$ESC[33m"

$Char_Window      = [char]::ConvertFromUtf32(0x1FA9F)
$Char_Loop        = [char]::ConvertFromUtf32(0x1F504)
$Char_CheckMark   = [char]0x2713
$Char_HeavyCheck  = [char]0x2705
$Char_FailureX    = [char]0x2716
$Char_Warn        = [char]0x26A0
$Char_Copyright   = [char]0x00A9

# Helper for consistent width centering
function Write-Centered {
    param([string]$Text, [string]$Color = $FGWhite)
    $Pad = [Math]::Max(0, [Math]::Floor((60 - $Text.Length) / 2))
    Write-Host (" " * $Pad + "$Color$Text$Reset")
}

# --- HEADER ---
Write-Host ""
Write-Host "$FGDarkBlue$([string]'_' * 60)$Reset"
Write-Centered "$Char_Window WinAuto $Char_Loop" $FGCyan
Write-Centered "DEV DRIVE PROTECTION" $FGCyan
Write-Host "$FGDarkGray$([string]'-' * 60)$Reset"
Write-Host ""

# --- MAIN LOGIC ---
try {
    # 1. Enable Performance Mode
    Write-Host "  ${FGWhite}Configuring Dev Drive Protection...$Reset"
    Write-Host "  ${FGGray}Setting Performance Mode to Enabled...$Reset" -NoNewline
    
    Set-MpPreference -PerformanceModeStatus Enabled -ErrorAction Stop
    Write-Host " $Char_CheckMark Success!" -ForegroundColor Green

    # 2. Verification
    Write-Host ""
    Write-Host "  ${FGWhite}Verification:$Reset"
    
    $mpPref = Get-MpPreference | Select-Object -ExpandProperty PerformanceModeStatus
    
    if ($mpPref -eq "Enabled") {
        Write-Host "  $FGDarkGreen $Char_HeavyCheck ENABLED  $Reset${FGGray}(PerformanceModeStatus)$Reset"
    } else {
        Write-Host "  $FGDarkRed $Char_FailureX DISABLED $Reset${FGGray}(Current: $mpPref)$Reset"
        Write-Host "  $FGDarkYellow $Char_Warn Warning: Setting might be managed by Group Policy.$Reset"
    }

    Write-Host ""
    Write-Host "  ${FGDarkGray}Note: Protection applies to trusted Dev Drives only.$Reset"

}
catch {
    Write-Host " $Char_FailureX Failure!" -ForegroundColor Red
    Write-Host "  $FGRed$($_.Exception.Message)$Reset"
}

# --- FOOTER ---
Write-Host ""
Write-Host "$FGDarkBlue$([string]'_' * 60)$Reset"
Write-Centered "$Char_Copyright 2026, www.AIIT.support. All Rights Reserved." $FGCyan
Write-Host ""