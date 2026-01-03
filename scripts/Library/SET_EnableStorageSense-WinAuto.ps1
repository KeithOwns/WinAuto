#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Configures Windows Storage Sense settings at the user level.
.DESCRIPTION
  Standardized for WinAuto. Automatically frees up disk space.
.PARAMETER Undo
  Resets Storage Sense settings to default by removing configurations.
#>

param(
    [switch]$Undo,
    [switch]$Disable, # Keep for compatibility
    [ValidateSet(1, 14, 30, 60)]
    [int]$RecycleBinDays = 30,
    [ValidateSet(0, 1, 14, 30, 60)]
    [int]$DownloadsDays = 60
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# Registry Path for Current User
$STORAGE_SENSE_USER_PATH = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"

Write-Header "STORAGE SENSE"

# --- MAIN ---

$statusText = if ($Undo -or $Disable) { "DISABLED" } else { "ENABLED" }
$isUndo = $Undo -or $Disable

try {
    if ($isUndo) {
        Write-LeftAligned "$FGGray Resetting Storage Sense user settings...$Reset"
        # Since Remove-RegistryValue isn't in Shared_UI_Functions yet, we implement simple logic here or assume it's added.
        # Given previous context, I should stick to standard PS or add Remove-RegistryValue to Shared.
        # For now, inline removal is safer to avoid dependency on a function I might not have added.
        Remove-ItemProperty -Path $STORAGE_SENSE_USER_PATH -Name "01" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $STORAGE_SENSE_USER_PATH -Name "2048" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $STORAGE_SENSE_USER_PATH -Name "04" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $STORAGE_SENSE_USER_PATH -Name "08" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $STORAGE_SENSE_USER_PATH -Name "32" -ErrorAction SilentlyContinue
        Write-LeftAligned "$FGGreen$Char_BallotCheck  Storage Sense is $statusText.$Reset"
    } else {
        Write-LeftAligned "$FGGray Enabling Storage Sense...$Reset"
        Set-RegistryDword -Path $STORAGE_SENSE_USER_PATH -Name "01" -Value 1
        Set-RegistryDword -Path $STORAGE_SENSE_USER_PATH -Name "2048" -Value 1
        Set-RegistryDword -Path $STORAGE_SENSE_USER_PATH -Name "04" -Value $RecycleBinDays
        Set-RegistryDword -Path $STORAGE_SENSE_USER_PATH -Name "08" -Value $DownloadsDays
        Set-RegistryDword -Path $STORAGE_SENSE_USER_PATH -Name "32" -Value 60
        Write-LeftAligned "$FGGreen$Char_BallotCheck  Storage Sense is $statusText.$Reset"
        Write-LeftAligned "  Recycle Bin: $RecycleBinDays days"
        Write-LeftAligned "  Downloads: $(if($DownloadsDays -eq 0){'Never'}else{$DownloadsDays.ToString() + ' days'})"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Failed: $($_.Exception.Message)$Reset"
}
