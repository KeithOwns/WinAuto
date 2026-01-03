#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks for Microsoft Store updates using UI Automation.
.DESCRIPTION
    Standardized for WinAuto. Opens MS Store and attempts to click 'Get updates'.
#>

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

Write-Header "MS STORE UPDATE CHECK"

try {
    Write-Step "Initializing UI Automation..."
    Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
    
    Write-Step "Launching Microsoft Store..."
    Start-Process "ms-windows-store://downloadsandupdates"
    Start-Sleep -Seconds 5

    $desktop = [System.Windows.Automation.AutomationElement]::RootElement
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, "Microsoft Store")
    $store = $desktop.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)

    if ($null -eq $store) {
        Write-Step "Microsoft Store window not found." -Level Error
        Start-Sleep -Seconds 1
        exit 1
    }

    Write-Step "Scanning for update buttons..."
    $btns = @("Get updates", "Check for updates", "Update all")
    $found = $false

    foreach ($text in $btns) {
        $bCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $text)
        $btn = $store.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $bCond)
        if ($null -ne $btn) {
            $btn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
            Write-Step "Successfully clicked '$text'." -Level Success
            $found = $true
            break
        }
    }

    if (-not $found) { Write-Step "Could not find update button automatically." -Level Warning }

} catch {
    Write-Step "Error: $($_.Exception.Message)" -Level Error
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






