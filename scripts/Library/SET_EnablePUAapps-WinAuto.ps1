#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enable or Disable Potentially Unwanted App (PUA) blocking.
.DESCRIPTION
    Standardized for WinAuto. Configures Defender PUA Protection.
.PARAMETER Undo
    Reverses the setting (Disables PUA apps blocking).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "PUA PROTECTION"

# --- MAIN ---

try {
    $status = if ($Undo) { "DISABLED" } else { "ENABLED" }
    $target = if ($Undo) { "Disabled" } else { "Enabled" }

    Set-MpPreference -PUAProtection $target
    
    # Verify
    $current = (Get-MpPreference).PUAProtection
    $match = if ($Undo) { $current -eq 0 } else { $current -eq 1 }

    if ($match) {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck  PUA App Blocking is $status.$Reset"
    } else {
        Write-LeftAligned "$FGRed$Char_RedCross  Verification failed. Status: $current$Reset"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed: $($_.Exception.Message)$Reset"
}






