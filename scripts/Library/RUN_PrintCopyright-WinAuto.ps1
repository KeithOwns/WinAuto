#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Prints a dynamic copyright notice.
.DESCRIPTION
    Standardized for WinAuto.
#>

# --- SHARED FUNCTIONS ---
if (Test-Path "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1") {
    . "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
} else {
    # Fallback if library missing
    $Char_Copyright = [char]0x00A9
    function Write-Centered { param($Text, $Width=60) Write-Host $Text }
}

# 1. Determine Year
$LastEditYear = (Get-Date).Year
if ($PSCommandPath) { $LastEditYear = (Get-Item $PSCommandPath).LastWriteTime.Year }

# 2. Output
$CopyrightLine = "$Char_Copyright $LastEditYear, www.AIIT.support. All Rights Reserved."
Write-Centered "$CopyrightLine"



