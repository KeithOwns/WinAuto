#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Master Control Suite
.DESCRIPTION
    The central hub for the WinAuto suite. Combines Windows Update, Security,
    Maintenance, and Application Deployment into a single unified interface.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- LOGGING SETUP ---
. "$PSScriptRoot\MODULE_Logging.ps1"
Init-Logging


# --- [USER PREFERENCE] CLEAR SCREEN START ---

# --------------------------------------------

# --- MAIN EXECUTION ---

$running = $true

while ($running) {

    Write-Header "MASTER CONTROL SUITE v3.0"
    
    Write-Host ""
    Write-LeftAligned " ${FGBlack}${BGYellow}[0]${Reset} ${FGGray}System Pre-Check ${FGDarkGray}(Health & Status)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[1]${Reset} ${FGGray}Windows Update ${FGDarkGray}(Set & Scan)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[2]${Reset} ${FGGray}Windows Security ${FGDarkGray}(Check & Fix)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[3]${Reset} ${FGGray}Maintenance ${FGDarkGray}(Optimize & Clean)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[4]${Reset} ${FGGray}App Installer ${FGDarkGray}(Select & Install)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[5]${Reset} ${FGGray}System Repair ${FGDarkGray}(SFC & DISM Flow)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[6]${Reset} ${FGGray}Debloat & Privacy ${FGDarkGray}(Remove Junk & Harden)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[7]${Reset} ${FGGray}System Restore ${FGDarkGray}(Revert Changes)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[8]${Reset} ${FGGray}Network Toolkit ${FGDarkGray}(Fix & Secure)${Reset}"
    Write-Host ""
    Write-LeftAligned " ${FGBlack}${BGYellow}[9]${Reset} ${FGGray}Utilities & Reports ${FGDarkGray}(Inventory, Batt, Logs...)${Reset}"
    Write-Host ""
    Write-LeftAligned " ${FGBlack}${BGYellow}[A]${Reset} ${FGGray}Run ${FGYellow}ALL${FGGray} Diagnostics (1-3, 5, 6)${Reset}"
    
    Write-Boundary $FGDarkBlue
    
    $prompt = "${FGWhite}$Char_Keyboard  Press${FGDarkGray} ${FGYellow}$Char_Finger [Key]${FGDarkGray} ${FGWhite}to${FGDarkGray} ${FGYellow}RUN${FGWhite}|${FGDarkGray}any other to ${FGWhite}EXIT$Char_Eject${Reset}"
    Write-Centered $prompt
    
    $inputStr = Read-Host "  $Char_Finger Selection"
    
    switch ($inputStr.Trim().ToUpper()) {
        '0' { & "$PSScriptRoot\CHECK_SystemPreCheck-WinAuto.ps1" }
        '1' { & "$PSScriptRoot\C1_WindowsUpdate_SETnSCAN.ps1"; Start-Sleep -Seconds 1 }
        '2' { & "$PSScriptRoot\C2_WindowsSecurity_CHECKnSETnSCAN.ps1"; Start-Sleep -Seconds 1 }
        '3' { & "$PSScriptRoot\C5_WindowsMaintenance_SETnSCAN.ps1" }
        '4' { 
            # App Installer Sub-Menu
            Write-Host ""
            Write-Boundary $FGDarkGray
            Write-Centered "${FGWhite}App Installer Setup"
            Write-LeftAligned " ${FGBlack}${BGYellow}[C]${Reset} ${FGGray}Configure / Edit App List${Reset}"
            Write-LeftAligned " ${FGBlack}${BGYellow}[I]${Reset} ${FGGray}Install Apps ${FGDarkGray}(Current Config)${Reset}"
            Write-Boundary $FGDarkGray
            $subPrompt = "${FGWhite}$Char_Keyboard  Press${FGDarkGray} ${FGYellow}$Char_Finger [Key]${FGDarkGray} ${FGWhite}to${FGDarkGray} ${FGYellow}Select${FGWhite}|${FGDarkGray}any other to ${FGWhite}BACK${Reset}"
            Write-Centered $subPrompt
            $subKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $subChar = $subKey.Character.ToString().ToUpper()
            if ($subChar -eq 'C') { & "$PSScriptRoot\SET_CreateAppConfig-WinAuto.ps1" } elseif ($subChar -eq 'I') { & "$PSScriptRoot\RUN_InstallAppsConfigurable-WinAuto.ps1"; Start-Sleep -Seconds 1 }
        }
        '5' { & "$PSScriptRoot\RUN_WindowsSFCRepair-WinAuto.ps1"; Start-Sleep -Seconds 1 }
        '6' { & "$PSScriptRoot\C3_WindowsDebloat_CLEAN.ps1"; Start-Sleep -Seconds 1 }
        '7' { & "$PSScriptRoot\RUN_SystemRestore-WinAuto.ps1" }
        '8' { & "$PSScriptRoot\C4_Network_FIXnSECURE.ps1"; Start-Sleep -Seconds 1 }
        '9' {
            # Utilities Sub-Menu
            $utilsRunning = $true
            while ($utilsRunning) {

                Write-Header "UTILITIES & REPORTS"
                Write-Host ""
                Write-LeftAligned " ${FGBlack}${BGYellow}[1]${Reset} ${FGGray}System Inventory ${FGDarkGray}(Report)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[2]${Reset} ${FGGray}Battery Health ${FGDarkGray}(Report)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[3]${Reset} ${FGGray}BSOD Analyzer ${FGDarkGray}(Logs)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[4]${Reset} ${FGGray}User Manager ${FGDarkGray}(Admin/Pass)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[5]${Reset} ${FGGray}Manage Startup ${FGDarkGray}(Boot)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[6]${Reset} ${FGGray}Bulk Uninstaller ${FGDarkGray}(Apps)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[7]${Reset} ${FGGray}Context Menu Integration${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[8]${Reset} ${FGGray}Configure Notifications${Reset}"
                Write-Host ""
                Write-LeftAligned " ${FGBlack}${BGYellow}[U]${Reset} ${FGGray}Update Suite ${FGDarkGray}(Git Pull)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[P]${Reset} ${FGGray}Pack Portable ${FGDarkGray}(Zip)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[R]${Reset} ${FGGray}Remote Execute ${FGDarkGray}(Deploy)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[D]${Reset} ${FGGray}Undo Debloat ${FGDarkGray}(Restore)${Reset}"
                Write-LeftAligned " ${FGBlack}${BGYellow}[X]${Reset} ${FGGray}Suite Cleanup ${FGDarkGray}(Delete)${Reset}"
                
                Write-Boundary $FGDarkBlue
                $uPrompt = "${FGWhite}$Char_Keyboard  Press${FGDarkGray} ${FGYellow}$Char_Finger [Key]${FGDarkGray} ${FGWhite}to${FGDarkGray} ${FGYellow}RUN${FGWhite}|${FGDarkGray}any other to ${FGWhite}BACK${Reset}"
                Write-Centered $uPrompt
                
                $uInput = Read-Host "  $Char_Finger Selection"
                switch ($uInput.Trim().ToUpper()) {
                    '1' { & "$PSScriptRoot\CHECK_SystemInventory-WinAuto.ps1" }
                    '2' { & "$PSScriptRoot\CHECK_BatteryHealth-WinAuto.ps1" }
                    '3' { & "$PSScriptRoot\CHECK_BSOD-WinAuto.ps1" }
                    '4' { & "$PSScriptRoot\SET_UserManager-WinAuto.ps1" }
                    '5' { & "$PSScriptRoot\SET_ManageStartup-WinAuto.ps1" }
                    '6' { & "$PSScriptRoot\RUN_BulkUninstaller-WinAuto.ps1" }
                    '7' { & "$PSScriptRoot\SET_IntegrationContextMenu-WinAuto.ps1" }
                    '8' { & "$PSScriptRoot\SET_SetupNotifications-WinAuto.ps1" }
                    'U' { & "$PSScriptRoot\RUN_UpdateSuite-WinAuto.ps1" }
                    'P' { & "$PSScriptRoot\RUN_PackPortable-WinAuto.ps1" }
                    'R' { & "$PSScriptRoot\RUN_RemoteExecute-WinAuto.ps1" }
                    'D' { & "$PSScriptRoot\C3_WindowsDebloat_CLEAN.ps1" -Undo }
                    'X' { & "$PSScriptRoot\RUN_SuiteCleanup-WinAuto.ps1" }
                    Default { $utilsRunning = $false }
                }
            }
        }
        'A' {
            Write-Host ""
            Write-LeftAligned "$FGYellow Running Full Suite...$Reset"
            Start-Sleep -Seconds 1
            & "$PSScriptRoot\C1_WindowsUpdate_SETnSCAN.ps1"
            & "$PSScriptRoot\C2_WindowsSecurity_CHECKnSETnSCAN.ps1"
            & "$PSScriptRoot\C5_WindowsMaintenance_SETnSCAN.ps1"
            & "$PSScriptRoot\RUN_WindowsSFCRepair-WinAuto.ps1"
            & "$PSScriptRoot\C3_WindowsDebloat_CLEAN.ps1" -AutoRun
            Write-Host ""
            Write-LeftAligned "$FGGreen$Char_BallotCheck Suite Complete.$Reset"
            Start-Sleep -Seconds 1
        }
        Default {
            $running = $false
            Write-Host ""
            Write-LeftAligned "$FGGray Exiting...$Reset"
            Start-Sleep -Milliseconds 500
        }
    }
}

# Report
Get-LogReport

# --- FOOTER ---
Write-Host ""
Write-Boundary $FGDarkBlue
$FooterText = "Â© $(Get-Date -Format 'yyyy'), www.AIIT.support. All Rights Reserved."
Write-Centered "$FGCyan$FooterText$Reset"
Write-Host ""




