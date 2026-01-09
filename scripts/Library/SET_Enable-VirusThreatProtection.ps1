#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables 'Virus & threat protection' in Windows Security via UI Automation.
.DESCRIPTION
    Launches Windows Security and attempts to click the 'Turn on' button
    associated with 'Virus & threat protection'.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Load .NET UIAutomation Assemblies
try {
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
} catch {
    Write-Error "Failed to load UIAutomation assemblies. Ensure .NET Framework is installed."
    exit 1
}

# --- HELPER FUNCTIONS ---

function Write-Log {
    param(
        [string]$Message,
        [ConsoleColor]$Color = "White"
    )
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Get-UIAElement {
    param(
        [System.Windows.Automation.AutomationElement]$Parent,
        [string]$Name,
        [System.Windows.Automation.ControlType]$ControlType,
        [System.Windows.Automation.TreeScope]$Scope = [System.Windows.Automation.TreeScope]::Descendants,
        [int]$TimeoutSeconds = 5
    )
    
    $Condition = if ($Name -and $ControlType) {
        $c1 = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $Name)
        $c2 = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, $ControlType)
        New-Object System.Windows.Automation.AndCondition($c1, $c2)
    } elseif ($Name) {
        New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $Name)
    } elseif ($ControlType) {
        New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, $ControlType)
    } else {
        throw "Must provide Name or ControlType"
    }

    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($StopWatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $Result = $Parent.FindFirst($Scope, $Condition)
        if ($Result) { return $Result }
        Start-Sleep -Milliseconds 500
    }
    return $null
}

function Invoke-UIAButton {
    param([System.Windows.Automation.AutomationElement]$Button)
    
    if (-not $Button) { return $false }
    
    try {
        $InvokePattern = $Button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
        $InvokePattern.Invoke()
        return $true
    } catch {
        Write-Log "Failed to invoke button: $_" "Red"
        return $false
    }
}

# --- MAIN SCRIPT ---

Write-Log "Starting Windows Security Automation..." "Cyan"

# 1. Launch Windows Security
Write-Log "Launching Windows Security..." "Gray"
Start-Process "windowsdefender:"
Start-Sleep -Seconds 2

# 2. Find the Main Window
$Desktop = [System.Windows.Automation.AutomationElement]::RootElement
$Window = Get-UIAElement -Parent $Desktop -Name "Windows Security" -ControlType ([System.Windows.Automation.ControlType]::Window) -Scope "Children" -TimeoutSeconds 10

if (-not $Window) {
    Write-Log "Could not find 'Windows Security' window." "Red"
    exit 1
}
Write-Log "Found 'Windows Security' window." "Green"

# 3. Focus Window (Optional but good practice)
try {
    $Window.SetFocus()
} catch {
    Write-Log "Could not set focus (might be minimized), attempting to continue..." "Yellow"
}

# 4. Navigate to Home (Security at a glance) if not there? 
# Usually starts there. We search for "Virus & threat protection" item.
# It is usually a 'Group' or 'ListItem' or just 'Text' depending on the view.
# However, the "Turn on" button is the target.
# Strategy: Find the "Virus & threat protection" Group/Pane, then find "Turn on" inside it.

Write-Log "Searching for 'Virus & threat protection' section..." "Gray"
# Note: The element name might just be "Virus & threat protection".
$Section = Get-UIAElement -Parent $Window -Name "Virus & threat protection" -Scope "Descendants" -TimeoutSeconds 5

if ($Section) {
    Write-Log "Found 'Virus & threat protection' section." "Green"
    
    # 5. Look for 'Turn on' button specifically under this section
    Write-Log "Looking for 'Turn on' button..." "Gray"
    
    # Sometimes hierarchy is tricky, search descendants of the section
    $TurnOnBtn = Get-UIAElement -Parent $Section -Name "Turn on" -ControlType ([System.Windows.Automation.ControlType]::Button) -Scope "Descendants" -TimeoutSeconds 3
    
    if (-not $TurnOnBtn) {
        # Fallback: Try searching the whole window for "Turn on" if section search failed (sometimes UI structure is flat)
        Write-Log "Button not found in section, searching entire window..." "Yellow"
        $TurnOnBtn = Get-UIAElement -Parent $Window -Name "Turn on" -ControlType ([System.Windows.Automation.ControlType]::Button) -Scope "Descendants" -TimeoutSeconds 3
    }

    if ($TurnOnBtn) {
        Write-Log "Found 'Turn on' button. Clicking..." "Cyan"
        if (Invoke-UIAButton -Button $TurnOnBtn) {
            Write-Log "Successfully clicked 'Turn on'." "Green"
        } else {
            Write-Log "Failed to click 'Turn on'." "Red"
        }
    } else {
        Write-Log "'Turn on' button not found. Maybe it's already on?" "Green"
    }

} else {
    Write-Log "Could not find 'Virus & threat protection' section." "Red"
    # Dump some children names for debugging if needed?
    # No, keep it simple.
}

Write-Log "Automation complete." "Cyan"
