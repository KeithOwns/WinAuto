#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables Automatic Sample Submission.
.DESCRIPTION
    Standardized for WinAuto. Configures sample submission consent for Microsoft Defender.
.PARAMETER Undo
    Reverses the setting (Disables Automatic Sample Submission).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "SAMPLE SUBMISSION"

# --- MAIN ---

try {
    # SubmitSamplesConsent: 0 = Never, 1 = SendSafeSamples (Always Prompt), 3 = SendAllSamples
    $target = if ($Undo) { 0 } else { 3 }
    $status = if ($Undo) { "DISABLED" } else { "ENABLED (Send All)" }

    Set-MpPreference -SubmitSamplesConsent $target -ErrorAction Stop

    # Verify
    $current = (Get-MpPreference).SubmitSamplesConsent
    if ($current -eq $target) {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck  Automatic Sample Submission is $status.$Reset"
    } else {
        Write-LeftAligned "$FGDarkYellow$Char_Warn Automatic Sample Submission verification failed.$Reset"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed: $($_.Exception.Message)$Reset"
}

