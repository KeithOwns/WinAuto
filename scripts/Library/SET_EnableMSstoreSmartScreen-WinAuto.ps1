#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables SmartScreen for Store apps (Current User).
.DESCRIPTION
    Standardized for WinAuto. Configures HKCU:\...\AppHost\EnableWebContentEvaluation.
.PARAMETER Undo
    Reverses the setting (Disables MS Store SmartScreen).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "MICROSOFT STORE SMARTSCREEN"

# --- CONFIG ---
$userPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost"
$valName  = "EnableWebContentEvaluation"
$targetValue = if ($Undo) { 0 } else { 1 }
$statusText = if ($Undo) { "DISABLED" } else { "ENABLED" }

# --- MAIN ---

try {
    if (-not (Test-Path $userPath)) { New-Item -Path $userPath -Force | Out-Null }
    
    Set-ItemProperty -Path $userPath -Name $valName -Value $targetValue -Type DWord -Force
    Write-LeftAligned "$FGGreen$Char_HeavyCheck  SmartScreen for Microsoft Store is $statusText.$Reset"

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed to modify Store SmartScreen: $($_.Exception.Message)$Reset"
}
