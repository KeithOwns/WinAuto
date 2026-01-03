#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Portable Packer
.DESCRIPTION
    Bundles the active suite into a clean ZIP file for portable deployment.
    Excludes archives, backups, and git metadata.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "PORTABLE PACKER"

$DateStr = Get-Date -Format "yyyy-MM-dd"
$ZipName = "WinAuto_Portable_$DateStr.zip"
$DestZip = Join-Path ($env:WinAutoLogDir) $ZipName
$SourceDir = (Get-Item $PSScriptRoot).Parent.FullName # scripts root
$ProjectRoot = (Get-Item $SourceDir).Parent.FullName # WinAuto root

# Temp Staging Area
$TempDir = Join-Path $env:TEMP "WinAuto_Stage_$DateStr"
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -Path $TempDir -ItemType Directory -Force | Out-Null

Write-Host "  $FGYellow Staging files...$Reset"

# 1. Copy Scripts (Main + Launcher)
$DestScripts = Join-Path $TempDir "scripts"
New-Item -Path $DestScripts -ItemType Directory -Force | Out-Null

Copy-Item -Path "$SourceDir\Main" -Destination $DestScripts -Recurse
Copy-Item -Path "$SourceDir\Launch_WinAuto.bat" -Destination $DestScripts
Copy-Item -Path "$SourceDir\scriptLibrary-W11" -Destination $DestScripts -Recurse

# 2. Copy Docs (Library)
$SourceDocs = Join-Path $ProjectRoot "docs"
if (Test-Path $SourceDocs) {
    $DestDocs = Join-Path $TempDir "docs"
    Copy-Item -Path $SourceDocs -Destination $DestDocs -Recurse
}

# 3. Clean Staging (Remove artifacts)
Write-Host "  $FGYellow Cleaning staging area...$Reset"
# Exclude git metadata, backup folders, and temporary logs
$Artifacts = Get-ChildItem -Path $TempDir -Recurse -Include "*.log", "*.bak", "tmp", "nppBackup", ".git*", ".gitignore" -ErrorAction SilentlyContinue
if ($Artifacts) { 
    $Artifacts | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "  $FGYellow Compressing to Desktop...$Reset"

# 4. Compress
if (Test-Path $DestZip) { Remove-Item $DestZip -Force }
Compress-Archive -Path "$TempDir\*" -DestinationPath $DestZip

# Cleanup
Remove-Item $TempDir -Recurse -Force

Write-Host ""
Write-LeftAligned "$FGGreen$Char_BallotCheck Portable Suite Created:$Reset"
Write-LeftAligned "$DestZip"
Write-Host ""

$null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
Write-Host ""








