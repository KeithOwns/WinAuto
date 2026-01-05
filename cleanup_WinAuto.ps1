# Requires -RunAsAdministrator

# 1. Clear the host per project standards
Clear-Host

Write-Host "--- WinAuto Pre-Push Cleanup ---" -ForegroundColor Cyan

# 2. Consolidate .gitignore
$GitignorePath = Join-Path $PSScriptRoot ".gitignore"
$TypoPath = Join-Path $PSScriptRoot ".gitnore.txt"

if (Test-Path $TypoPath) {
    Write-Host "[*] Merging and removing .gitnore.txt typo file..."
    $TypoContent = Get-Content $TypoPath
    Add-Content -Path $GitignorePath -Value "`n# Imported from typo file`n$TypoContent"
    Remove-Item $TypoPath -Force
}

# 3. Create Directories
$DocsDir = Join-Path $PSScriptRoot "docs"
$DevDir = Join-Path $PSScriptRoot "dev"

if (!(Test-Path $DocsDir)) { New-Item -ItemType Directory -Path $DocsDir | Out-Null }
if (!(Test-Path $DevDir)) { New-Item -ItemType Directory -Path $DevDir | Out-Null }

# 4. Move Documentation
if (Test-Path (Join-Path $PSScriptRoot "MANIFEST.md")) {
    Write-Host "[*] Moving MANIFEST.md to docs/..."
    Move-Item -Path (Join-Path $PSScriptRoot "MANIFEST.md") -Destination (Join-Path $DocsDir "MANIFEST.md") -Force
}

# 5. Move Dev Tools
if (Test-Path (Join-Path $PSScriptRoot "scriptRULES-WinAuto.ps1")) {
    Write-Host "[*] Moving linter to dev/..."
    Move-Item -Path (Join-Path $PSScriptRoot "scriptRULES-WinAuto.ps1") -Destination (Join-Path $DevDir "scriptRULES-WinAuto.ps1") -Force
}

Write-Host ""
Write-Host "Cleanup complete. Your root directory is now ready for GitHub!" -ForegroundColor Green

# 6. Print 5 empty lines before exit per project standards
Write-Host "`n`n`n`n"
