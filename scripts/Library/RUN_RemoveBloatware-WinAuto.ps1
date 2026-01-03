#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Removes Bloatware or Restores Default Apps.
.DESCRIPTION
    Standardized for WinAuto. Removes common junk apps or attempts restoration.
.PARAMETER Undo
    Reverses the operation (Attempts to reinstall all default apps).
#>

param([switch]$Undo)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- BLOATWARE LISTS ---
$ThirdPartyBloat = @(
    "*Spotify*", "*Disney*", "*Netflix*", "*Instagram*", "*TikTok*", "*Facebook*", "*Twitter*", "*CandyCrush*", "*LinkedIn*", "*GamingApp*"
)
$MicrosoftBloat = @(
    "*BingNews*", "*BingWeather*", "*GetHelp*", "*GetStarted*", "*Microsoft365Hub*", "*SolitaireCollection*", "*Todos*", "*FeedbackHub*", "*YourPhone*", "*Cortana*"
)

# --- MAIN ---

Write-Header "BLOATWARE MANAGER"

try {
    if ($Undo) {
        Write-LeftAligned "$FGYellow Attempting to restore all default Windows apps...$Reset"
        Write-LeftAligned "  $FGGray (This may take several minutes and show some errors)$Reset"
        Get-AppxPackage -AllUsers | ForEach-Object {
            if ($_.InstallLocation -and (Test-Path "$($_.InstallLocation)\AppXManifest.xml")) {
                Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue
            }
        }
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Restoration process complete.$Reset"
    } else {
        Write-LeftAligned "$FGYellow Scanning and removing bloatware apps...$Reset"
        $list = $ThirdPartyBloat + $MicrosoftBloat
        $found = 0
        foreach ($pattern in $list) {
            $app = Get-AppxPackage -Name $pattern -ErrorAction SilentlyContinue
            if ($app) {
                Write-LeftAligned "  Removing: $($app.Name)"
                $app | Remove-AppxPackage -ErrorAction SilentlyContinue
                $found++
            }
        }
        Write-Host ""
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Removed $found bloatware apps.$Reset"
    }

} catch { Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset" }

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






