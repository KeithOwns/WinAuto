#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto App Manager
.DESCRIPTION
    A unified launcher for all application management tools in the WinAuto suite.
    Includes Installer, Uninstaller, Browser, and Configuration Wizard.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

function Write-MenuItem { param($Id, $Text, $Desc) Write-Host "  [$Id] $Bold$Text$Reset" -NoNewline; if ($Desc) { Write-Host " - $Desc" -ForegroundColor Gray } else { Write-Host "" } }

# --- MAIN LOOP ---
$running = $true

while ($running) {

    Write-Header "APP MANAGER"
    Write-Host ""
    
    Write-MenuItem "1" "Install Apps (Configurable)" "Run the automated installer based on JSON config"
    Write-MenuItem "2" "Bulk Uninstaller" "Select and remove multiple apps at once"
    Write-MenuItem "3" "App Library Browser" "Browse and launch installers/links from docs folder"
    Write-MenuItem "4" "Configure Installer" "Wizard to create/edit Install_Apps-Config.json"
    
    Write-Host ""
    Write-Boundary
    # Added Timeout Functionality
    $PromptCursorTop = [Console]::CursorTop
    $TickAction = {
        param($ElapsedTimespan)
        $WiggleFrame = [Math]::Floor($ElapsedTimespan.TotalMilliseconds / 500)
        $IsRight = ($WiggleFrame % 2) -eq 1
        if ($IsRight) { $CurrentChars = @(" ", $Char_Finger, "[", "E", "n", "t", "e", "r", "]", " ") } 
        else { $CurrentChars = @($Char_Finger, " ", "[", "E", "n", "t", "e", "r", "]", " ") }
        $FilledCount = [Math]::Floor($ElapsedTimespan.TotalSeconds)
        if ($FilledCount -gt 10) { $FilledCount = 10 }
        $DynamicPart = ""
        for ($i = 0; $i -lt 10; $i++) {
            $Char = $CurrentChars[$i]
            if ($i -lt $FilledCount) { $DynamicPart += "${BGYellow}${FGBlack}$Char${Reset}" } 
            else { if ($Char -eq " ") { $DynamicPart += " " } else { $DynamicPart += "${FGYellow}$Char${Reset}" } }
        }
        $PromptStr = "${FGWhite}$Char_Keyboard  Press ${FGDarkGray}$DynamicPart${FGDarkGray}${FGWhite}to${FGDarkGray} ${FGYellow}EXIT${FGDarkGray} ${FGWhite}|${FGDarkGray} or Type Selection$Char_Skip${Reset}"
        try { [Console]::SetCursorPosition(0, $PromptCursorTop); Write-Host (" " * 4) + $PromptStr -NoNewline } catch {}
    }
    
    $key = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
    Write-Host ""
    if ($key.VirtualKeyCode -eq 13) { $val = "" } else { $val = $key.Character.ToString() }
    
    switch ($val) {
        '1' { & "$PSScriptRoot\RUN_Install_Apps-Configurable.ps1" }
        '2' { & "$PSScriptRoot\RUN_Bulk_Uninstaller.ps1" }
        '3' { & "$PSScriptRoot\RUN_AppLibrary_Browser.ps1" }
        '4' { & "$PSScriptRoot\SET_Create_AppConfig.ps1" }
        Default { $running = $false }
    }
}






