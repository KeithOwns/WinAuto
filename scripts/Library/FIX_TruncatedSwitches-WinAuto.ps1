#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fixes truncated switch cases in WinAuto scripts.
.DESCRIPTION
    Adds missing closing braces to lines ending with 'Start-Sleep -Seconds 1'.
#>

$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scripts = Get-ChildItem -Path $rootDir -Filter "*.ps1" -Recurse

foreach ($s in $scripts) {
    $lines = Get-Content -Path $s.FullName
    $changed = $false
    $newLines = @()
    foreach ($line in $lines) {
        # Match lines like '1' { ... ; Start-Sleep -Seconds 1
        # but only if they don't already have a closing brace
        if ($line -match "^\s*'.*'\s*\{.*Start-Sleep -Seconds 1\s*$" -and $line -notmatch "\}") {
            Write-Host "Fixing truncated line in $($s.Name): $line" -ForegroundColor Cyan
            $newLines += $line + " }"
            $changed = $true
        } else {
            $newLines += $line
        }
    }
    if ($changed) {
        $newLines | Out-File -FilePath $s.FullName -Encoding UTF8
    }
}

