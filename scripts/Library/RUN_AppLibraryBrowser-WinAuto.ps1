#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto App Library Browser
.DESCRIPTION
    Dynamically scans the 'docs\LINKs' and 'docs\INSTALLers' directories to 
    provide an interactive menu for launching installers and download links.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- STYLE & FORMATTING ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Esc = [char]0x1B
$Reset = "$Esc[0m"
$Bold = "$Esc[1m"
$FGCyan = "$Esc[96m"; $FGGreen = "$Esc[92m"; $FGWhite = "$Esc[97m"; $FGGray = "$Esc[37m"
$FGDarkBlue = "$Esc[34m"; $FGDarkGray = "$Esc[90m"; $FGYellow = "$Esc[93m"; $FGRed = "$Esc[91m"
$BGYellow = "$Esc[103m"; $FGBlack = "$Esc[30m"
$Char_HeavyLine = [char]0x2501; $Char_Keyboard = [char]0x2328; $Char_Finger = [char]0x261B
$Char_Skip = [char]0x23ED; $Char_Eject = [char]0x23CF; $Char_HeavyMinus = [char]0x2796

# --- PATHS ---
$LibraryPath = "C:\Users\admin\Documents\GitHub\WinAuto\docs\Installer_LINKs-W11"

# --- HELPER FUNCTIONS ---
function Write-Centered { param($Text, $Width = 60) $clean = $Text -replace "$Esc\[[0-9;]*m", ""; $pad = [Math]::Floor(($Width - $clean.Length) / 2); Write-Host (" " * [Math]::Max(0,$pad) + $Text) }
function Write-LeftAligned { param($Text, $Indent = 2) Write-Host (" " * $Indent + $Text) }
function Write-Header { param($Title) Write-Host ""; Write-Centered "$Bold$FGCyan $Char_HeavyLine WinAuto $Char_HeavyLine $Reset"; Write-Centered "$Bold$FGCyan$Title$Reset"; Write-Host "$FGDarkBlue$([string]$Char_HeavyLine * 60)$Reset" }
function Write-Boundary { param([string]$Color = $FGDarkBlue) Write-Host "$Color$([string]$Char_HeavyLine * 60)$Reset" }

# --- DISCOVERY ---
function Get-AppLibrary {
    $apps = @()
    
    if (Test-Path $LibraryPath) {
        # Scan for all executable/link types recursively
        Get-ChildItem -Path $LibraryPath -File -Recurse -Include *.exe, *.msi, *.bat, *.url, *.lnk | ForEach-Object {
            $name = $_.BaseName -replace '^INSTALL[-\s]|^DL[-\s]|^LINK[-\s]', ''
            $type = if ($_.Extension -match 'url|lnk') { "Web/Shortcut" } else { "Local Installer" }
            $cat = if ($_.DirectoryName -ne $LibraryPath) { (Split-Path $_.DirectoryName -Leaf) } else { "Main" }
            
            $apps += [pscustomobject]@{ 
                Name = $name; 
                Path = $_.FullName; 
                Type = $type; 
                Category = $cat 
            }
        }
    }
    return $apps | Sort-Object Category, Name
}

# --- MAIN LOOP ---
$allApps = @(Get-AppLibrary)
$running = $true

while ($running) {

    Write-Header "APP LIBRARY BROWSER"
    
    if ($allApps.Count -eq 0) {
        Write-LeftAligned "$FGRed No applications found in docs folder.$Reset"
        $running = $false; Pause; continue
    }

    $currentCat = ""
    for ($i=0; $i -lt $allApps.Count; $i++) {
        $app = $allApps[$i]
        if ($app.Category -ne $currentCat) {
            $currentCat = $app.Category
            Write-Host ""
            Write-LeftAligned "$Bold$FGWhite$Char_HeavyMinus $currentCat$Reset"
        }
        $idx = "$FGYellow[$($i+1)]$Reset"
        $typeInfo = if ($app.Type -eq "Local Installer") { "$FGGreen(Installer)$Reset" } else { "$FGDarkGray(Link)$Reset" }
        Write-LeftAligned " $idx $($app.Name) $typeInfo"
    }

    Write-Host ""
    Write-Boundary $FGDarkBlue
    $prompt = "${FGWhite}$Char_Keyboard  Type${FGYellow} ID ${FGWhite}to Launch${FGWhite}|${FGDarkGray}any other to ${FGWhite}EXIT$Char_Eject${Reset}"
    Write-Centered $prompt
    
    Write-Host ""
    $val = Read-Host "  $Char_Finger Selection"
    
    if ($val -match '^\d+$') {
        $idx = [int]$val - 1
        if ($idx -ge 0 -and $idx -lt $allApps.Count) {
            $target = $allApps[$idx]
            Write-LeftAligned "$FGGreen Launching $($target.Name)...$Reset"
            try {
                Start-Process $target.Path
                Start-Sleep -Seconds 1
            } catch {
                Write-LeftAligned "$FGRed Failed to launch: $($_.Exception.Message)$Reset"
                Pause
            }
        }
    } else {
        $running = $false
    }
}

Write-Host ""
Write-Centered "$FGCyan Â© $(Get-Date -Format 'yyyy'), AIIT.support $Reset"
Write-Host ""



