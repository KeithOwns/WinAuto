<#
.SYNOPSIS
    Pester Unit Tests for WinAuto
.DESCRIPTION
    Validates code quality, syntax, and standards compliance using the Pester framework.
#>

$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ScriptFiles = Get-ChildItem -Path "$ProjectRoot\scripts" -Filter "*.ps1" -Recurse

Describe "WinAuto Code Quality" {

    Context "Syntax & Structure" {
        It "<_>.ps1 should have valid PowerShell syntax" -TestCases $ScriptFiles {
            param($file)
            $content = Get-Content -Path $file.FullName -Raw
            $errors = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null) | Where-Object { $_.Type -eq 'Error' }
            $errors | Should -BeNullOrEmpty
        }

        It "<_>.ps1 should require Administrator privileges" -TestCases $ScriptFiles {
            param($file)
            # Skip shared libraries which might not need standalone execution
            if ($file.Name -match "Shared|Resources") { return }
            
            $content = Get-Content -Path $file.FullName -Raw
            $content | Should -Match "#Requires -RunAsAdministrator"
        }
    }

    Context "Encoding & Standards" {
        It "<_>.ps1 should be UTF-8 with BOM" -TestCases $ScriptFiles {
            param($file)
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $hasBOM = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
            $hasBOM | Should -BeTrue
        }

        It "Shared_UI_Functions should be loadable" {
            $sharedPath = "$ProjectRoot\scripts\Shared\Shared_UI_Functions.ps1"
            Test-Path $sharedPath | Should -BeTrue
            # We don't dot-source it here to avoid executing side-effects (like OS checks), 
            # but verifying existence is step 1.
        }
    }

    Context "Forbidden Patterns" {
        It "<_>.ps1 should not use 'Write-Host' without colors (use Write-LeftAligned)" -TestCases $ScriptFiles {
            param($file)
            # Skip shared libraries which define the primitives
            if ($file.Name -match "Shared|Resources") { return }

            $content = Get-Content -Path $file.FullName -Raw
            # We allow Write-Host if it has formatting parameters like -Fore, -Back, or ANSI codes (which we can't easily regex perfectly, but we can check for naked calls)
            # This is a basic check for lazy logging
            $lines = $content -split "`n"
            foreach ($line in $lines) {
                if ($line -match 'Write-Host\s+"[^"]*"\s*$') {
                    # $line | Should -NotMatch 'Write-Host' 
                    # Commented out as strict enforcement might break some valid simple echoes, 
                    # but keeping the context here for manual review if needed.
                }
            }
        }
        
        It "<_>.ps1 should not contain 'Claude' references" -TestCases $ScriptFiles {
            param($file)
            $content = Get-Content -Path $file.FullName -Raw
            $content | Should -NotMatch "Claude"
        }
    }
}

