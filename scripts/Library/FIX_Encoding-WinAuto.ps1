#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fixes encoding for all PowerShell scripts in the project.
.DESCRIPTION
    Converts all .ps1 and .psm1 files to UTF-8 with BOM as per WinAuto standards.
#>

# --- SHARED FUNCTIONS ---
$SharedFunctions = Join-Path $PSScriptRoot "..\Shared\Shared_UI_Functions.ps1"
if (Test-Path $SharedFunctions) {
    . $SharedFunctions
} else {
    $FGGreen = ""; $FGRed = ""; $FGYellow = ""; $FGCyan = ""; $FGGray = ""; $Reset = ""
    $Char_HeavyCheck = "v"; $Char_RedCross = "x"; $Char_HeavyLine = "="
    function Write-Header { param($t) Write-Host "--- $t ---" }
    function Write-Centered { param($t, $w=60) Write-Host $t }
    function Write-LeftAligned { param($t, $i=2) Write-Host (" "*$i + $t) }
    function Write-Boundary { param($c="") Write-Host ("=" * 60) }
}

Write-Header "FIX ENCODING (UTF-8 BOM)"

$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$files = Get-ChildItem -Path $rootDir -Filter "*.ps1" -Recurse
$files += Get-ChildItem -Path $rootDir -Filter "*.psm1" -Recurse

$count = 0
foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $isUTF8BOM = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    
    if (-not $isUTF8BOM) {
        Write-LeftAligned "$FGYellow Fixing: $($f.FullName.Replace($rootDir.Path, ''))$Reset"
        $content = Get-Content -Path $f.FullName -Raw
        [System.IO.File]::WriteAllLines($f.FullName, $content, (New-Object System.Text.UTF8Encoding($true)))
        $count++
    }
}

Write-Boundary
Write-Centered "$FGGreen Fixed $count files.$Reset"
Write-Boundary

