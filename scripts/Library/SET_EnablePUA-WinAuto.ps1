#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables Potentially Unwanted App (PUA) blocking.
.DESCRIPTION
    Standardized for WinAuto. Configures:
    1. Windows Defender PUA Protection (System-wide)
    2. Edge SmartScreen PUA Protection (User-specific 'Block downloads')
.PARAMETER Undo
    Reverses the setting (Disables PUA blocking).
#>

param(
    [switch]$Undo,
    [switch]$Force
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "PUA PROTECTION"

# --- MAIN ---

try {
    $targetMp = if ($Undo) { 0 } else { 1 }
    $targetEdge = if ($Undo) { 0 } else { 1 }
    $statusText = if ($Undo) { "DISABLED" } else { "ENABLED" }

    # 1. System-wide Defender PUA
    Set-MpPreference -PUAProtection $targetMp -ErrorAction Stop
    Write-LeftAligned "$FGGreen$Char_HeavyCheck  Defender PUA Blocking is $statusText.$Reset"

    # 2. User-specific Edge SmartScreen PUA (Block downloads)
    $edgeKeyPath = "HKCU:\Software\Microsoft\Edge\SmartScreenPuaEnabled"
    if (!(Test-Path $edgeKeyPath)) {
        New-Item -Path $edgeKeyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $edgeKeyPath -Name "(default)" -Value $targetEdge -Type DWord -Force
    Write-LeftAligned "$FGGreen$Char_HeavyCheck  Edge 'Block downloads' is $statusText.$Reset"

    # Verification
    $currentMp = (Get-MpPreference).PUAProtection
    # Defender PUA: 0=Disabled, 1=Enabled, 2=Audit
    $matchMp = ($currentMp -eq $targetMp)
    
    if (-not $matchMp) {
        Write-LeftAligned "$FGDarkYellow$Char_Warn Verification failed for Defender PUA. Status: $currentMp$Reset"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed: $($_.Exception.Message)$Reset"
}