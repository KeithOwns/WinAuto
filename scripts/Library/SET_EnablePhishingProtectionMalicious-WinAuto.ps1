#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enable or Disable "Warn me about malicious apps and sites" in Phishing Protection.
.DESCRIPTION
    Standardized for WinAuto. Configures SmartScreen and Phishing Protection in HKCU.
.PARAMETER Undo
    Reverses the setting (Disables malicious warnings).
#>

param(
    [switch]$Undo,
    [switch]$Force
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "MALICIOUS APP WARNING"

# --- MAIN ---

try {
    $targetValue = if ($Undo) { 0 } else { 1 }
    $statusText = if ($Undo) { "DISABLED" } else { "ENABLED" }

    $smartscreenPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost"
    $phishKey = "HKCU:\Software\Microsoft\Windows Security Health\PhishingProtection"

    if (!(Test-Path $smartscreenPath)) { New-Item -Path $smartscreenPath -Force | Out-Null }
    if (!(Test-Path $phishKey)) { New-Item -Path $phishKey -Force | Out-Null }

    # Set values
    Set-ItemProperty -Path $smartscreenPath -Name "EnableWebContentEvaluation" -Value $targetValue -Type DWord
    Set-ItemProperty -Path $phishKey -Name "WarnMaliciousAppsAndSites" -Value $targetValue -Type DWord

    Write-LeftAligned "$FGGreen$Char_HeavyCheck  Malicious App Warning is $statusText.$Reset"

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed: $($_.Exception.Message)$Reset"
}






