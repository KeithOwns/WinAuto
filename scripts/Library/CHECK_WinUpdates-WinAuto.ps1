#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Opens the Windows Update settings page and triggers a check.
.DESCRIPTION
  Standardized for WinAuto. Uses UI Automation.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

#region Helper Functions
function Write-Step {
    param([string]$Message, [ValidateSet('Info','Success','Warning','Error')]$Level = 'Info')
    $color = switch ($Level) { 'Info'{'Cyan'}; 'Success'{'Green'}; 'Warning'{'Yellow'}; 'Error'{'Red'} }
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}
#endregion

# --- MAIN ---

Write-Header "WINDOWS UPDATE CHECK"

try {
    Write-Step "Initializing UI Automation..."
    Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
    
    Write-Step "Launching Settings..."
    Start-Process "ms-settings:windowsupdate"
    Start-Sleep -Seconds 5

    $desktop = [System.Windows.Automation.AutomationElement]::RootElement
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, "Settings")
    $win = $desktop.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)

    if ($null -eq $win) {
        Write-Step "Settings window not found." -Level Error
        Start-Sleep -Seconds 1
        exit 1
    }

    Write-Step "Scanning for update button..."
    $btnCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, "Check for updates")
    $btn = $win.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $btnCond)

    if ($null -ne $btn) {
        $btn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
        Write-Step "Successfully clicked 'Check for updates'." -Level Success
    } else {
        Write-Step "Could not find the button. It may be hidden or disabled." -Level Warning
    }

} catch {
    Write-Step "Error: $($_.Exception.Message)" -Level Error
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






