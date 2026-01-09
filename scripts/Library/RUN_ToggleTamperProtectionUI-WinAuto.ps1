#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Attempts to toggle Tamper Protection via UI Automation.
.DESCRIPTION
    Opens 'windowsdefender://threatsettings' and uses .NET UI Automation to find and click the Tamper Protection toggle.
    This is a "best effort" attempt as Windows Security UI elements can be dynamic or protected.
#>

param()

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- LOGGING SETUP ---
. "$PSScriptRoot\MODULE_Logging.ps1"
Init-Logging

Write-Header "TAMPER PROTECTION UI TOGGLE"

try {
    # 1. Load Assemblies
    try {
        Add-Type -AssemblyName UIAutomationClient
        Add-Type -AssemblyName UIAutomationTypes
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Failed to load UI Automation assemblies.$Reset"
        Write-Log "Failed to load UI Automation assemblies" "ERROR"
        exit
    }

    # 2. Launch Settings Page
    Write-LeftAligned "$FGGray Opening Virus & threat protection settings...$Reset"
    Start-Process "windowsdefender://threatsettings"
    Write-Log "Launched windowsdefender://threatsettings" "INFO"

    # 3. Wait for Window
    $timeout = 10
    $startTime = Get-Date
    $secWindow = $null
    
    Write-LeftAligned "$FGGray Waiting for Windows Security window...$Reset"
    
    do {
        $desktop = [System.Windows.Automation.AutomationElement]::RootElement
        $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, "Windows Security")
        $secWindow = $desktop.FindFirst([System.Windows.Automation.TreeScope]::Children, $condition)
        if ($secWindow -ne $null) { break }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $startTime.AddSeconds($timeout))

    if ($secWindow -eq $null) {
        Write-LeftAligned "$FGRed$Char_RedCross Could not find Windows Security window.$Reset"
        Write-Log "Windows Security window not found within timeout" "ERROR"
        exit
    }

    Start-Sleep -Seconds 2 # Allow UI to render

    # 4. Find Tamper Protection Toggle
    Write-LeftAligned "$FGGray Searching for Tamper Protection switch...$Reset"
    
    # Strategy: Find by Name and Click (Blind, like Windows Update script)
    $targetName = "Tamper protection"
    $buttonCondition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $targetName)
    $toggle = $secWindow.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $buttonCondition)

    if ($toggle -ne $null) {
        # Try InvokePattern first (Standard Click)
        $invokePattern = $toggle.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
        
        if ($invokePattern -ne $null) {
             $invokePattern.Invoke()
             Write-LeftAligned "$FGGreen$Char_HeavyCheck Successfully clicked '$targetName'.$Reset"
             Write-Log "Invoked Tamper Protection toggle via UI Automation" "SUCCESS"
        }
        # Fallback: Some switches only support TogglePattern
        elseif ($null -ne ($togglePattern = $toggle.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern))) {
             $togglePattern.Toggle()
             Write-LeftAligned "$FGGreen$Char_HeavyCheck Successfully toggled '$targetName'.$Reset"
             Write-Log "Toggled Tamper Protection via UI Automation" "SUCCESS"
        }
        else {
             Write-LeftAligned "$FGRed$Char_Warn Found element but cannot click it (No supported pattern).$Reset"
             Write-Log "Found element but no Invoke/Toggle pattern" "WARNING"
        }
    } else {
        Write-LeftAligned "$FGDarkMagenta$Char_Warn Could not find '$targetName' toggle.$Reset"
        Write-LeftAligned "   (Note: Scroll down might be required if not visible, or UI structure changed)"
        Write-Log "Tamper protection toggle not found in visual tree" "WARNING"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross UI Automation Error: $($_.Exception.Message)$Reset"
    Write-Log "Fatal UI Error: $($_.Exception.Message)" "ERROR"
}

Write-Host ""
Write-Boundary
Write-Centered "$FGCyan Done.$Reset"
Write-Host ""
