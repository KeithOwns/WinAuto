#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fixes common function name corruptions in WinAuto scripts.
.DESCRIPTION
    Replaces corrupted 'function Start-Sleep -Seconds 1' with correct WinAuto function names.
#>

$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scripts = Get-ChildItem -Path $rootDir -Filter "*.ps1" -Recurse

foreach ($s in $scripts) {
    $content = Get-Content -Path $s.FullName -Raw
    if ($content -match 'function Start-Sleep -Seconds 1') {
        Write-Host "Fixing function names in: $($s.Name)" -ForegroundColor Yellow
        
        # We need to be careful with double occurrences
        $lines = Get-Content -Path $s.FullName
        $newLines = @()
        $foundCount = 0
        foreach ($line in $lines) {
            if ($line -match '^function Start-Sleep -Seconds 1') {
                $foundCount++
                if ($foundCount -eq 1) {
                    $newLines += 'function Wait-KeyPressWithTimeout {'
                } elseif ($foundCount -eq 2) {
                    $newLines += 'function Invoke-AnimatedPause {'
                } else {
                    $newLines += $line # Should not happen based on current audit
                }
            } else {
                $newLines += $line
            }
        }
        $newLines | Out-File -FilePath $s.FullName -Encoding UTF8
    }
}
