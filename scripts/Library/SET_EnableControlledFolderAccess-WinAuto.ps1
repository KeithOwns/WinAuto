#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables Controlled Folder Access.
.DESCRIPTION
    Standardized for WinAuto. Protects files and folders from unauthorized changes by unfriendly applications.
.PARAMETER Undo
    Reverses the setting (Disables Controlled Folder Access).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "CONTROLLED FOLDER ACCESS"

# --- MAIN ---

try {
    # EnableControlledFolderAccess: 0 = Disabled, 1 = Enabled
    $target = if ($Undo) { 0 } else { 1 }
    $status = if ($Undo) { "DISABLED" } else { "ENABLED" }

    Set-MpPreference -EnableControlledFolderAccess $target -ErrorAction Stop

    # Verify
    $current = (Get-MpPreference).EnableControlledFolderAccess
    if ($current -eq $target) {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck  Controlled Folder Access is $status.$Reset"
    } else {
        Write-LeftAligned "$FGDarkYellow$Char_Warn Controlled Folder Access verification failed.$Reset"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed: $($_.Exception.Message)$Reset"
}

