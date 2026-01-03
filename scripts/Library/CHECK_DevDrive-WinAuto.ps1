#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Check for Dev Drive volumes on the system.
.DESCRIPTION
    Standardized for WinAuto. Detects ReFS-based Dev Drives.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "DEV DRIVE CHECK"

Write-LeftAligned "$FGYellow Scanning for Dev Drive volumes (ReFS)...$Reset"

try {
    $refs = Get-Volume | Where-Object { $_.FileSystem -eq "ReFS" -and $_.DriveLetter }

    if ($refs) {
        Write-Host ""
        Write-LeftAligned "$FGGreen$Char_BallotCheck Dev Drive(s) detected:$Reset"
        $refs | Format-Table DriveLetter, FileSystemLabel, @{Name="Size(GB)";Exp={[math]::Round($_.Size/1GB,2)}}, @{Name="Free(GB)";Exp={[math]::Round($_.SizeRemaining/1GB,2)}} -AutoSize
    } else {
        Write-LeftAligned "$FGGray No Dev Drive volumes found.$Reset"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






