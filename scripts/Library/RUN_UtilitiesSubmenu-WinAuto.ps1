#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Utilities & Reports Sub-Menu
.DESCRIPTION
    Modular sub-menu for advanced system reports, user management, and suite utilities.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

function Write-MenuItem { param($Id, $Text, $Desc) Write-Host "  [$Id] $Bold$Text$Reset" -NoNewline; if ($Desc) { Write-Host " - $Desc" -ForegroundColor Gray } else { Write-Host "" } }

# --- MAIN LOOP ---
$utilsRunning = $true
while ($utilsRunning) {

    Write-Header "UTILITIES & REPORTS"
    Write-Host ""
    
    Write-MenuItem "1" "System Inventory" "Comprehensive hardware & software report"
    Write-MenuItem "2" "Battery Health" "Detailed battery wear and cycle report"
    Write-MenuItem "3" "BSOD Analyzer" "Analyze recent system crash logs"
    Write-MenuItem "4" "User Manager" "Manage admin rights and passwords"
    Write-MenuItem "5" "Manage Startup" "Optimize boot performance"
    Write-MenuItem "6" "Bulk Uninstaller" "Quickly remove multiple applications"
    Write-MenuItem "7" "Context Menu Fix" "Toggle Classic vs Modern right-click"
    Write-MenuItem "8" "Notifications" "Configure system alert settings"
    Write-MenuItem "9" "Quick Fixes" "Targeted repairs (Printer, Audio, Search)"
    Write-Host ""
    Write-MenuItem "U" "Update Suite" "Pull latest version from repository"
    Write-MenuItem "P" "Pack Portable" "Create a portable zip of the suite"
    Write-MenuItem "R" "Remote Execute" "Deploy scripts to remote systems"
    Write-MenuItem "X" "Suite Cleanup" "Remove logs and temporary files"
    
    Write-Host ""
    Write-Boundary
    
    $PromptCursorTop = [Console]::CursorTop
    $TickAction = {
        param($ElapsedTimespan)
        $Remaining = [Math]::Max(0, 15 - [Math]::Floor($ElapsedTimespan.TotalSeconds))
        $PromptStr = "${FGWhite}$Char_Keyboard Select ${FGYellow}[Key]${FGWhite} or ${FGDarkGray}BACK${FGWhite} in ${BGYellow}${FGBlack} $Remaining ${Reset}${FGGray}s...${Reset}"
        try { [Console]::SetCursorPosition(0, $PromptCursorTop); Write-Centered $PromptStr } catch {}
    }
    
    $keyInput = Wait-KeyPressWithTimeout -Seconds 15 -OnTick $TickAction
    $selection = if ($keyInput.VirtualKeyCode -eq 13) { "" } else { $keyInput.Character.ToString().ToUpper() }

    switch ($selection) {
    '1' { & "$PSScriptRoot\CHECK_SystemInventory-WinAuto.ps1"; Invoke-AnimatedPause -ActionText "RETURN" }
    '2' { & "$PSScriptRoot\CHECK_BatteryHealth-WinAuto.ps1"; Invoke-AnimatedPause -ActionText "RETURN" }
    '3' { & "$PSScriptRoot\CHECK_BSOD-WinAuto.ps1"; Invoke-AnimatedPause -ActionText "RETURN" }
    '4' { & "$PSScriptRoot\SET_UserManager-WinAuto.ps1" }
    '5' { & "$PSScriptRoot\SET_ManageStartup-WinAuto.ps1" }
    '6' { & "$PSScriptRoot\RUN_BulkUninstaller-WinAuto.ps1" }
    '7' { & "$PSScriptRoot\SET_IntegrationContextMenu-WinAuto.ps1" }
    '8' { & "$PSScriptRoot\SET_SetupNotifications-WinAuto.ps1" }
    
    'U' { & "$PSScriptRoot\RUN_UpdateSuite-WinAuto.ps1" }
    'P' { & "$PSScriptRoot\RUN_PackPortable-WinAuto.ps1" }
    'R' { & "$PSScriptRoot\RUN_RemoteExecute-WinAuto.ps1" }
    'X' { & "$PSScriptRoot\RUN_SuiteCleanup-WinAuto.ps1" }
        Default { $utilsRunning = $false }
    }
}

