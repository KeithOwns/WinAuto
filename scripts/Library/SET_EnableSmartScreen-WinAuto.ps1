#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables Windows Defender SmartScreen.
.DESCRIPTION
    Standardized for WinAuto. Sets SmartScreenEnabled="Warn" (Enable) or "Off" (Disable) in HKLM.
.PARAMETER Undo
    Reverses the setting (Disables SmartScreen).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "SMARTSCREEN"

# --- MAIN ---

try {
    $target = if ($Undo) { "Off" } else { "Warn" }
    $status = if ($Undo) { "DISABLED" } else { "ENABLED" }

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
    $regName = "SmartScreenEnabled"

    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

    # Set the registry key
    Set-ItemProperty -Path $regPath -Name $regName -Value $target -Force

    Write-LeftAligned "$FGGreen$Char_HeavyCheck  SmartScreen for Apps and Files is $status.$Reset"

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed to modify SmartScreen: $($_.Exception.Message)$Reset"
}
