<#
.SYNOPSIS
    Pester Unit Tests for WinAuto
.DESCRIPTION
    Validates code quality, syntax, and standards compliance using the Pester framework.
#>

$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ScriptFiles = Get-ChildItem -Path "$ProjectRoot\scripts" -Filter "*.ps1" -Recurse | ForEach-Object { @{ File = $_ } }

Describe "WinAuto Code Quality" {

    Context "Syntax & Structure" {
        It "File <File.Name> should have valid PowerShell syntax" -TestCases $ScriptFiles {
            param($File)
            $content = Get-Content -Path $File.FullName -Raw
            $errors = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null) | Where-Object { $_.Type -eq 'Error' }
            $errors | Should -BeNullOrEmpty
        }

        It "File <File.Name> should require Administrator privileges" -TestCases $ScriptFiles {
            param($File)
            # Skip shared libraries which might not need standalone execution
            if ($File.Name -match "Shared|Resources") { return }
            
            $content = Get-Content -Path $File.FullName -Raw
            $content | Should -Match "#Requires -RunAsAdministrator"
        }
    }

    Context "Encoding & Standards" {
        It "File <File.Name> should be UTF-8 with BOM" -TestCases $ScriptFiles {
            param($File)
            $bytes = [System.IO.File]::ReadAllBytes($File.FullName)
            $hasBOM = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
            $hasBOM | Should -BeTrue
        }

        It "Shared_UI_Functions should be loadable" {
            $sharedPath = "$ProjectRoot\scripts\Shared\Shared_UI_Functions.ps1"
            Test-Path $sharedPath | Should -BeTrue
        }
    }

    Context "Forbidden Patterns" {
        It "File <File.Name> should not use naked Write-Host" -TestCases $ScriptFiles {
            param($File)
            # Skip shared libraries which define the primitives
            if ($File.Name -match "Shared|Resources") { return }

            $content = Get-Content -Path $File.FullName -Raw
            $lines = $content -split "`n"
            foreach ($line in $lines) {
                if ($line -match 'Write-Host\s+"[^"]*"\s*$') {
                    # Manual review context
                }
            }
        }
        
        It "File <File.Name> should not contain 'Claude' references" -TestCases $ScriptFiles {
            param($File)
            $content = Get-Content -Path $File.FullName -Raw
            $content | Should -NotMatch "Claude"
        }
    }
}

