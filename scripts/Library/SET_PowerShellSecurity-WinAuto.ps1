#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables advanced PowerShell Security Logging (Blue Team Hardening).
.DESCRIPTION
    Configures Group Policy Registry keys to enable:
    1. Script Block Logging (Event ID 4104) - Captures de-obfuscated code.
    2. Module Logging (Event ID 4103) - Captures pipeline execution.
    3. Transcription - Saves full session input/output to a local directory.
    
    This turns PowerShell into a "surveillance camera" for system activity.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
. "$PSScriptRoot\WinAuto_Functions.ps1"

Write-Header "POWERSHELL SECURITY"

$RegPath_PS = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
$RegPath_SBL = "$RegPath_PS\ScriptBlockLogging"
$RegPath_Mod = "$RegPath_PS\ModuleLogging"
$RegPath_Trn = "$RegPath_PS\Transcription"
$RegPath_ModNames = "$RegPath_Mod\ModuleNames"

$TranscriptDir = "$env:ProgramData\WinAuto\PowerShell_Transcripts"

try {
    # 1. Script Block Logging
    if (-not (Test-Path $RegPath_SBL)) { New-Item -Path $RegPath_SBL -Force | Out-Null }
    Set-RegistryDword -Path $RegPath_SBL -Name "EnableScriptBlockLogging" -Value 1
    Set-RegistryDword -Path $RegPath_SBL -Name "EnableScriptBlockInvocationLogging" -Value 1
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Script Block Logging Enabled (Deep Visibility).$Reset"

    # 2. Module Logging
    if (-not (Test-Path $RegPath_ModNames)) { New-Item -Path $RegPath_ModNames -Force | Out-Null }
    Set-RegistryDword -Path $RegPath_Mod -Name "EnableModuleLogging" -Value 1
    Set-RegistryString -Path $RegPath_ModNames -Name "*" -Value "*"
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Module Logging Enabled (All Modules).$Reset"

    # 3. Transcription
    if (-not (Test-Path $RegPath_Trn)) { New-Item -Path $RegPath_Trn -Force | Out-Null }
    
    # Create Transcript Directory
    if (-not (Test-Path $TranscriptDir)) { 
        New-Item -Path $TranscriptDir -ItemType Directory -Force | Out-Null 
        # Hide the directory
        $item = Get-Item -Path $TranscriptDir
        $item.Attributes = "Hidden"
    }

    Set-RegistryDword -Path $RegPath_Trn -Name "EnableTranscripting" -Value 1
    Set-RegistryString -Path $RegPath_Trn -Name "OutputDirectory" -Value $TranscriptDir
    Set-RegistryDword -Path $RegPath_Trn -Name "EnableInvocationHeader" -Value 1
    
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Transcription Enabled.$Reset"
    Write-LeftAligned "   $FGGray Path: $TranscriptDir$Reset"

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Failed to apply PowerShell hardening: $($_.Exception.Message)$Reset"
}
