#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Standardizes interactive timeout logic in WinAuto scripts.
.DESCRIPTION
    Replaces corrupted 'Start-Sleep -Seconds 1' calls with 'Wait-KeyPressWithTimeout' 
    where appropriate, using the correct parameters.
#>

$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$scripts = Get-ChildItem -Path $rootDir -Filter "*.ps1" -Recurse

foreach ($s in $scripts) {
    $content = Get-Content -Path $s.FullName -Raw
    $changed = $false
    
    # Pattern 1: $key = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction (expecting Wait-KeyPressWithTimeout)
    if ($content -match '\$key\s*=\s*Start-Sleep -Seconds 1') {
        Write-Host "Fixing logic in $($s.Name)" -ForegroundColor Green
        $content = $content -replace '\$key\s*=\s*Start-Sleep -Seconds 1', '$key = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction'
        $changed = $true
    }
    
    # Pattern 2: $resKey = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
    if ($content -match '\$resKey\s*=\s*Start-Sleep -Seconds 1') {
        Write-Host "Fixing logic in $($s.Name)" -ForegroundColor Green
        $content = $content -replace '\$resKey\s*=\s*Start-Sleep -Seconds 1', '$resKey = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction'
        $changed = $true
    }

    # Pattern 3: $null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction (at the end of scripts for Pause)
    # Only if Invoke-AnimatedPause or Wait-KeyPressWithTimeout is defined or dot-sourced
    if ($content -match '\$null\s*=\s*Start-Sleep -Seconds 1') {
        # If Invoke-AnimatedPause is available (either defined or dot-sourced)
        if ($content -match 'Invoke-AnimatedPause' -or $content -match 'Shared_UI_Functions.ps1') {
             Write-Host "Fixing pause logic in $($s.Name)" -ForegroundColor Green
             $content = $content -replace '\$null\s*=\s*Start-Sleep -Seconds 1', '$null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction'
             $changed = $true
        }
    }

    if ($changed) {
        $content | Out-File -FilePath $s.FullName -Encoding UTF8
    }
}

