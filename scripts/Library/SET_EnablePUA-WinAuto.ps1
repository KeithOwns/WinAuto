#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables Potentially Unwanted App (PUA) Blocking.
.DESCRIPTION
    Standardized for WinAuto. Configures Defender PUA protection.
.PARAMETER Undo
    Reverses the setting (Disables PUA Protection).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "PUA PROTECTION"

# --- MAIN ---
$statusText = if ($Undo) { "DISABLED" } else { "ENABLED" }
$targetValue = if ($Undo) { 0 } else { 1 }

try {
    Set-MpPreference -PUAProtection $targetValue -ErrorAction Stop

    # Verify
    $current = (Get-MpPreference).PUAProtection
    if ($current -eq $targetValue) {
        Write-LeftAligned "$FGGreen$Char_BallotCheck  PUA Protection is $statusText.$Reset"
    } else {
        Write-LeftAligned "$FGRed$Char_RedCross  PUA Protection $statusText failed.$Reset"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed: $($_.Exception.Message)$Reset"
}

