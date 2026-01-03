#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables the Dynamic Lock feature in Windows 10/11.
.DESCRIPTION
    Standardized for WinAuto. Sets EnableGoodbye=1 (Enable) or 0 (Disable) in Registry.
.PARAMETER Undo
    Reverses the setting (Disables Dynamic Lock).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- CONFIG ---
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
$regName = "EnableGoodbye"
$targetValue = if ($Undo) { 0 } else { 1 }
$actionText = if ($Undo) { "Disabling" } else { "Enabling" }
$statusText = if ($Undo) { "Disabled" } else { "Enabled" }

# --- MAIN ---

Write-Header "DYNAMIC LOCK CONFIG"

try {
    Write-LeftAligned "$FGYellow $actionText Dynamic Lock...$Reset"
    
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name $regName -Value $targetValue -Type DWord -Force
    
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Dynamic Lock has been $statusText.$Reset"
    
    if (-not $Undo) {
        Write-Host ""
        Write-LeftAligned "$FGYellow$Char_Warn Reminder: Ensure your smartphone is paired via Bluetooth.$Reset"
    }

} catch {
    Write-Host ""
    Write-LeftAligned "$FGRed$Char_RedCross Failed: $($_.Exception.Message)$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






