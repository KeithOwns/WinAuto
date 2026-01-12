#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bulk Application Uninstaller
.DESCRIPTION
    Lists installed applications via Winget and allows batch uninstallation.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "BULK UNINSTALLER"

Write-Host ""
Write-LeftAligned "$FGYellow Scanning installed applications (Winget)...$Reset"
Write-LeftAligned "$FGGray This may take a moment.$Reset"

try {
    # Get-Winget output parsing is tricky. 
    # Best way is to use `winget list` but parsing columns is hard.
    # We will try to filter for user apps (exclude system components if possible, but winget shows most).
    
    # We'll use a trick: `winget list --accept-source-agreements`
    # We can't easily capture objects. We'll display them and ask for ID search or name match?
    # No, we promised a selection list.
    
    # Let's try to get a list we can parse.
    # Note: This is simplified. Robust parsing of `winget` text output requires regex.
    # We will focus on apps that have an ID.
    
    # Alternative: Use Get-Package (PackageManagement) but it's slower.
    # Let's stick to a simple "Search to Uninstall" flow or "Show Top 50".
    # Listing ALL 200+ apps is messy in console.
    
    # UPDATED STRATEGY: "Search & Select"
    Write-Host ""
    $filter = Read-Host "  $Char_Finger Enter name filter (e.g. 'Adobe' or press Enter for ALL)"
    
    Write-LeftAligned "$FGYellow Fetching list...$Reset"
    $listRaw = winget list "$filter" --accept-source-agreements 2>&1
    
    # Parse output simply: Skip header, assume columns Name, Id, Version...
    # Winget output is fixed width. 
    # Name (0-35), Id (36-70 approx)... 
    # Actually, we can just display the raw lines with an index number!
    
    $lines = $listRaw -split "`n" | Where-Object { $_ -match '\s\s+' -and $_ -notmatch '^Name\s+Id' -and $_ -notmatch '^-+' }
    
    if ($lines.Count -eq 0) {
        Write-LeftAligned "$FGRed No applications found matching '$filter'.$Reset"
        exit
    }
    
    $selectionMap = @{}
    $loop = $true
    
    while ($loop) {

        Write-Header "BULK UNINSTALLER"
        Write-LeftAligned "$FGGray Filter: '$filter'$Reset"
        Write-Host ""
        
        for ($i=0; $i -lt $lines.Count; $i++) {
            # Simple truncation for display
            $line = $lines[$i].Trim()
            if ($line.Length -gt 70) { $line = $line.Substring(0, 70) + "..." }
            
            $mark = if ($selectionMap[$i]) { "$FGRed$Char_Trash$Reset" } else { " " }
            $idx = "$FGYellow[$($i+1)]$Reset"
            
            Write-Host "  $idx $mark $line"
        }
        
        Write-Host ""
        Write-Boundary
        $prompt = "${FGWhite}$Char_Keyboard  Type${FGYellow} ID ${FGWhite}to Mark${FGWhite}|${FGDarkGray}press Enter to ${FGWhite}UNINSTALL${Reset}"
        Write-Centered $prompt
        
        Write-Host ""
        $val = Read-Host "  $Char_Finger Selection"
        
        if ([string]::IsNullOrWhiteSpace($val)) {
            $loop = $false
        } elseif ($val -match '^\d+$') {
            $idx = [int]$val - 1
            if ($idx -ge 0 -and $idx -lt $lines.Count) {
                $selectionMap[$idx] = -not $selectionMap[$idx]
            }
        }
    }
    
    # Execute Uninstall
    $targets = @()
    foreach ($k in $selectionMap.Keys) {
        if ($selectionMap[$k]) { $targets += $lines[$k] }
    }
    
    if ($targets.Count -eq 0) { exit }

    # Restore Point
    Write-Host ""
    Write-LeftAligned "$FGYellow Creating System Restore Point...$Reset"
    try {
        Checkpoint-Computer -Description "WinAuto Bulk Uninstall $(Get-Date -Format 'yyyyMMdd_HHmm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-LeftAligned "$FGGreen$Char_BallotCheck Restore Point created.$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_Warn Skip Restore Point: $($_.Exception.Message)$Reset"
    }
    
    Write-Boundary
    Write-LeftAligned "$FGRed Uninstalling $($targets.Count) applications...$Reset"
    
    foreach ($line in $targets) {
        # Extract ID. Usually the second column.
        # This is a bit fragile but works for most standard winget outputs.
        # Strategy: Split by multiple spaces.
        $parts = $line -split '\s{2,}'
        if ($parts.Count -ge 2) {
            $id = $parts[1]
            $name = $parts[0]
            Write-Host ""
            Write-LeftAligned "$FGYellow Uninstalling: $name ($id)...$Reset"
            winget uninstall --id "$id" --accept-source-agreements
        } else {
            Write-LeftAligned "$FGRed Could not parse ID from line: $line$Reset"
        }
    }
    
    Write-LeftAligned "$FGGreen$Char_BallotCheck Batch complete.$Reset"

} catch {
    Write-LeftAligned "$FGRed Error: $($_.Exception.Message)$Reset"
}

Write-Host ""
$null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
Write-Host ""






