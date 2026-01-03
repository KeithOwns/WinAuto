#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Validates PowerShell script quality and consistency.
.DESCRIPTION
    Standardized for WinAuto. Tests encoding, syntax, and admin requirements.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath = $PSScriptRoot
)

# --- SHARED FUNCTIONS ---
if (Test-Path "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1") {
    . "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
} else {
    # Partial fallback for standalone
    $FGGreen = ""; $FGRed = ""; $FGYellow = ""; $FGCyan = ""; $FGGray = ""; $Reset = ""
    $Char_HeavyCheck = "v"; $Char_RedCross = "x"
    function Write-Header { param($t) Write-Host "--- $t ---" }
    function Write-Centered { param($t, $w=60) Write-Host $t }
    function Write-LeftAligned { param($t, $i=2) Write-Host (" "*$i + $t) }
    function Write-Boundary { param($c="") Write-Host "------------------------------------------------------------" }
}

# Test result tracking
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:Issues = @()

#region Helper Functions

function Write-StepResult {
    param([string]$TestName, [bool]$Passed, [string]$Message = "")
    $script:TotalTests++
    if ($Passed) {
        $script:PassedTests++
        Write-Host "  $FGGreen$Char_HeavyCheck$Reset $FGGray$TestName$Reset"
    } else {
        $script:FailedTests++
        Write-Host "  $FGRed$Char_RedCross$Reset $FGYellow$TestName - $Message$Reset"
        $script:Issues += [PSCustomObject]@{ Test = $TestName; Message = $Message }
    }
}

#endregion

# --- MAIN ---

Write-Header "SCRIPT QUALITY AUDIT"

Write-LeftAligned "$FGYellow Scanning scripts in: $ScriptPath$Reset"
$scripts = Get-ChildItem -Path $ScriptPath -Filter "*.ps1" -Recurse -File | Where-Object { $_.Name -ne "CHECK_ScriptQuality-W11.ps1" }

if ($scripts.Count -eq 0) {
    Write-LeftAligned "$FGRed No scripts found to test.$Reset"
    Start-Sleep -Seconds 1
    exit 1
}

Write-Host ""
foreach ($s in $scripts) {
    $fName = $s.Name
    $content = Get-Content -Path $s.FullName -Raw
    
    # 1. Admin Requirement
    $hasAdmin = $content -match '#Requires\s+-RunAsAdministrator'
    Write-StepResult -TestName "Admin Req: $fName" -Passed $hasAdmin -Message "Missing Admin directive"
    
    # 2. Encoding (Heuristic)
    $bytes = [System.IO.File]::ReadAllBytes($s.FullName)
    $isUTF8 = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Write-StepResult -TestName "UTF-8 BOM: $fName" -Passed $isUTF8 -Message "Not UTF-8 with BOM"
    
    # 3. Syntax
    $errs = $null
    [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errs) | Out-Null
    Write-StepResult -TestName "Syntax: $fName" -Passed ($errs.Count -eq 0) -Message "$($errs.Count) errors found"
}

# Summary
Write-Host ""
Write-Boundary $FGDarkBlue
Write-Centered "$FGCyan TEST SUMMARY $Reset"
Write-LeftAligned "Total Tests : $FGCyan$script:TotalTests$Reset"
Write-LeftAligned "Passed      : $FGGreen$script:PassedTests$Reset"
Write-LeftAligned "Failed      : $(if($script:FailedTests -gt 0){$FGRed}else{$FGGreen})$script:FailedTests$Reset"
Write-Boundary $FGDarkBlue

if ($script:Issues.Count -gt 0) {
    Write-Host ""
    Write-Centered "$FGRed !!! ISSUES DETECTED !!! $Reset"
}

Start-Sleep -Seconds 1
Write-Host ""






