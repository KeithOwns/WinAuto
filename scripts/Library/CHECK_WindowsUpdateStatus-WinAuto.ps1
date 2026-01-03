#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks for pending Windows Updates.
.DESCRIPTION
    Standardized for WinAuto. Uses COM to search for uninstalled updates.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "WINDOWS UPDATE STATUS"

try {
    Write-LeftAligned "$FGYellow Contacting Windows Update Service...$Reset"
    
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
    
    $Pending = $SearchResult.Updates.Count
    
    if ($Pending -eq 0) {
        Write-LeftAligned "$FGGreen$Char_BallotCheck System is up to date.$Reset"
    } else {
        Write-LeftAligned "$FGYellow$Char_Warn $Pending updates available.$Reset"
        Write-Host ""
        foreach ($u in $SearchResult.Updates) {
            Write-LeftAligned "$FGWhite â€¢ $($u.Title)$Reset"
        }
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






