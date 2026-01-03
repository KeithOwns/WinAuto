#Requires -RunAsAdministrator
param([switch]$AutoRun)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- [USER PREFERENCE] CLEAR SCREEN START ---

function Get-RegistryValue {
    param([Parameter(Mandatory)] [string]$Path, [Parameter(Mandatory)] [string]$Name)
    try {
        if (Test-Path $Path) {
            $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            return $prop.$Name
        }
        return $null
    } catch { return $null }
}

function Set-RegistryDword {
    param([Parameter(Mandatory)] [string]$Path, [Parameter(Mandatory)] [string]$Name, [Parameter(Mandatory)] [int]$Value)
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
        Write-Log -Message "Set registry: $Path\$Name = $Value" -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to set registry: $Path\$Name - $($_.Exception.Message)" -Level ERROR
        throw $_ 
    }
}

# Registry Paths
$WU_UX  = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
$WU_POL = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$WINLOGON_USER = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 
$WINLOGON_MACHINE = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

function Show-WUStatus {
    Write-Boundary $FGDarkGray

    Write-Host " $Bold$FGWhite Windows Update$Reset"
    
    $status_WindowsUpdate = "Updates available"
    $status_Color = $FGDarkMagenta
    $status_Icon = $Char_Warn
    $LastSearchStr = "Unknown"
    
    # Defaults
    $iconColor = $Char_Warn
    $timestampColor = $FGGray
    
    try {
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        $UpdateSearcher.Online = $false
        
        $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
        if ($SearchResult.Updates.Count -eq 0) {
            $status_WindowsUpdate = "You're up to date"
            $status_Color = $FGWhite
            $status_Icon = $Char_Loop
        }
        
        $AutoUpdate = New-Object -ComObject Microsoft.Update.AutoUpdate
        $LastSearch = $AutoUpdate.Results.LastSearchSuccessDate
        
        if ($LastSearch) {
             $LastSearchStr = $LastSearch.ToString()
             
             # Calculate 48 Hour Logic
             $TimeDiff = (Get-Date) - $LastSearch
             if ($TimeDiff.TotalHours -lt 48) {
                 # < 48h: DarkGreen
                 $iconColor = $FGDarkGreen
                 $timestampColor = $FGDarkGreen
             } else {
                 # > 48h: DarkRed
                 $iconColor = $FGDarkRed
                 $timestampColor = $FGDarkRed
             }
        }
    } catch {
        $status_WindowsUpdate = "Check status failed"
        $status_Color = $FGDarkRed
        $status_Icon = $Char_XSquare
    }
    
    Write-Host ""
    
    # --- CHANGED: Updates Available Logic ---
    if ($status_WindowsUpdate -eq "Updates available") {
        # Updates found: Print in Magenta and HIDE 'Last checked'
        Write-LeftAligned "$FGDarkMagenta$Char_Warn $FGDarkMagenta$status_WindowsUpdate$Reset"
    }
    else {
        # Updates NOT found (or check failed): Use standard logic + 'Last checked'
        Write-LeftAligned "$iconColor$status_Icon $status_Color$status_WindowsUpdate$Reset"
        Write-LeftAligned "$FGGray Last checked: $timestampColor$LastSearchStr$Reset"
    }
    # ----------------------------------------
    
    Write-Log -Message "Starting Windows Update status check" -Level INFO

    Write-Host ""
    Write-LeftAligned "$Bold$FGWhite More options$Reset"
    
    $continuous = Get-RegistryValue -Path $WU_UX -Name "IsContinuousInnovationOptedIn"
    
    Write-FlexLine -LeftIcon $Char_Speaker -LeftText "Get latest updates ASAP" -RightText "On" -IsActive ($continuous -eq 1) -ActiveColor $BGDarkGreen

    Write-Host ""
    Write-LeftAligned "$Bold$FGWhite$Char_Gear  Advanced options $Reset"
    
    $mu = Get-RegistryValue -Path $WU_UX  -Name "AllowMUUpdateService"
    Write-FlexLine -LeftIcon $Char_Loop -LeftText "Receive updates for other Microsoft products" -RightText "On" -IsActive ($mu -eq 1)

    # Added -Width 59 to shift the RightText one space to the left
    $expedited = Get-RegistryValue -Path $WU_UX -Name "IsExpedited"
    Write-FlexLine -LeftIcon $Char_FastForward -LeftText "Get me up to date: Restart ASAP" -RightText "On" -IsActive ($expedited -eq 1) -Width 59

    $metered = Get-RegistryValue -Path $WU_UX -Name "AllowAutoWindowsUpdateDownloadOverMeteredNetwork"
    # Updated Icon: > becomes $Char_Timer (⏲)
    # Added leading space to LeftText to align 'D' in Download with 'G' in Get above
    Write-FlexLine -LeftIcon $Char_Timer -LeftText " Download updates over metered connections" -RightText "On" -IsActive ($metered -eq 1)

    # Moved here:
    $restartNotify = Get-RegistryValue -Path $WU_UX -Name "RestartNotificationsAllowed2"
    Write-FlexLine -LeftIcon $Char_Bell -LeftText "Notify me when a restart is required" -RightText "On" -IsActive ($restartNotify -eq 1)

    $ahs = Get-RegistryValue -Path $WU_UX -Name "ActiveHoursStart"
    $ahe = Get-RegistryValue -Path $WU_UX -Name "ActiveHoursEnd"
    
    $TimeText = "Auto"
    if ($ahs -ne $null -and $ahe -ne $null) {
        $dateStart = (Get-Date).Date.AddHours($ahs)
        $dateEnd = (Get-Date).Date.AddHours($ahe)
        $TimeText = "Currently " + $dateStart.ToString("h:mm tt") + " to " + $dateEnd.ToString("h:mm tt")
    }

    # Modified alignment: 
    # Reduced padding to exactly 2 spaces as requested.
    # Updated Icon: $Char_Timer becomes $Char_Alarm (⏰)
    
    Write-Host (" " * 3) -NoNewline
    Write-Host "$FGGray$Char_Alarm Active hours:$Reset" -NoNewline
    Write-Host (" " * 2) -NoNewline
    Write-Host "$Reset$TimeText$Reset"
    
    Write-Host ""
    Write-LeftAligned "$Bold$FGWhite$Char_User Accounts >  Sign-in options$Reset"
    
    $restartApps = Get-RegistryValue -Path $WINLOGON_USER -Name "RestartApps"
    Write-FlexLine -LeftIcon ">" -LeftText "Automatically save restartable apps" -RightText "On" -IsActive ($restartApps -eq 1)
    
    $arsoEnabled = $false
    try {
        $UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        if ($UserSID) {
            $userArsoPath = "$WINLOGON_MACHINE\UserARSO\$UserSID"
            $optOut = Get-RegistryValue -Path $userArsoPath -Name "OptOut"
            $arsoEnabled = ($optOut -ne $null -and $optOut -eq 0)
        }
    } catch { $arsoEnabled = $false }
    
    Write-FlexLine -LeftIcon ">" -LeftText "Use sign-in info to finish setup after update" -RightText "On" -IsActive $arsoEnabled

    Write-Host ""
    Write-Boundary $FGDarkGray
}

function Set-WUSettings {
    try {
        Write-Log -Message "Applying Windows Update configurations" -Level INFO
        Set-RegistryDword -Path $WU_UX -Name "IsContinuousInnovationOptedIn" -Value 1
        Set-RegistryDword -Path $WU_UX -Name "AllowMUUpdateService" -Value 1
        Set-RegistryDword -Path $WU_UX -Name "IsExpedited" -Value 1
        Set-RegistryDword -Path $WU_UX -Name "AllowAutoWindowsUpdateDownloadOverMeteredNetwork" -Value 1
        Set-RegistryDword -Path $WU_UX -Name "RestartNotificationsAllowed2" -Value 1
        
        try {
            Set-RegistryDword -Path $WINLOGON_USER -Name "RestartApps" -Value 1
            $policyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            $policyName = "DisableAutomaticRestartSignOn"
            $policyValue = Get-RegistryValue -Path $policyPath -Name $policyName

            if ($null -ne $policyValue -and $policyValue -eq 1) {
                Write-Log -Message "ARSO blocked by policy" -Level WARNING
            } else {
                $UserSID = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
                if (-not $UserSID) { throw "Could not determine current user's SID." }
                $userArsoPath = "$WINLOGON_MACHINE\UserARSO\$UserSID"
                Set-RegistryDword -Path $WINLOGON_MACHINE -Name "ARSOUserConsent" -Value 1
                if (-not (Test-Path $userArsoPath)) { New-Item -Path $userArsoPath -Force -ErrorAction Stop | Out-Null }
                Set-RegistryDword -Path $userArsoPath -Name "OptOut" -Value 0
            }
        } catch {
             Write-Log -Message "Failed to set user sign-in options: $($_.Exception.Message)" -Level ERROR
        }
    }
    catch {
        Write-Log -Message "Error applying settings: $($_.Exception.Message)" -Level ERROR
    }
}

function Invoke-COMUpdateCheck {
    Write-Host "$FGDarkGray$([string]$Char_LightLine * 60)$Reset"
    Write-Centered "$Char_EnDash Update SEARCH (COM) $Char_EnDash" -Color "$Bold$FGCyan"
    Write-Host ""

    try {
        Write-LeftAligned "$FGGray Contacting Windows Update Service...$Reset"
        Write-Log -Message "Initializing COM Update Searcher" -Level INFO
        
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        
        $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
        $PendingUpdates = $SearchResult.Updates.Count
        
        if ($PendingUpdates -eq 0) {
            Write-LeftAligned "$FGGreen$Char_HeavyCheck System is up to date.$Reset"
            Write-Log -Message "COM Search: No updates found" -Level SUCCESS
        } else {
            Write-LeftAligned "$FGDarkMagenta$Char_Warn Updates available: $PendingUpdates$Reset"
            Write-Log -Message "COM Search: $PendingUpdates updates found" -Level INFO
            
            Write-Host ""
            Write-BodyTitle "Available updates"
            foreach ($Update in $SearchResult.Updates) {
                Write-LeftAligned "  $Char_Finger $($Update.Title)"
                Write-Log -Message "Available: $($Update.Title)" -Level INFO
            }
        }
        
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Error checking status: $($_.Exception.Message)$Reset"
        Write-Log -Message "COM Check Error: $($_.Exception.Message)" -Level ERROR
    }
}

function Invoke-WingetUpdateCheck {
    Write-Host "$FGDarkGray$([string]$Char_LightLine * 60)$Reset"
    Write-Centered "$Char_EnDash WINGET SOFTWARE UPDATE $Char_EnDash" -Color "$Bold$FGCyan"
    Write-Host ""

    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
        Write-LeftAligned "$FGGray Checking for software updates via Winget...$Reset"
        Write-Log -Message "Starting Winget upgrade all" -Level INFO
        
        # Run upgrade
        # --include-unknown ensures we catch apps with versioning quirks
        # --accept-package-agreements for headless automation
        $args = @("upgrade", "--all", "--include-unknown", "--accept-package-agreements", "--accept-source-agreements", "--silent")
        Start-Process "winget.exe" -ArgumentList $args -Wait -NoNewWindow
        
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Winget update command completed.$Reset"
    } else {
        Write-LeftAligned "$FGDarkMagenta$Char_Warn Winget not found. Skipping.$Reset"
    }
}

function Invoke-MSStoreUpdateCheck {
    Write-Host "$FGDarkGray$([string]$Char_LightLine * 60)$Reset"
    Write-Centered "$Char_EnDash Microsoft Store CHECK $Char_EnDash" -Color "$Bold$FGCyan"
    Write-Host ""

    try {
        Add-Type -AssemblyName UIAutomationClient
        Add-Type -AssemblyName UIAutomationTypes
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Failed to load UI Automation assemblies$Reset"
        Write-Log -Message "Failed to load UI Automation assemblies" -Level ERROR
        return
    }

    Write-LeftAligned "$FGGray Opening Microsoft Store to check for app updates...$Reset"
    Write-Log -Message "Attempting to open Microsoft Store for updates" -Level INFO
    Start-Process "ms-windows-store://downloadsandupdates"
    
    # RESTORED: Name-based logic
    $buttonTexts = @("Get updates", "Check for updates", "Update all")
    
    # Start loop for wait
    $timeout = 10
    $startTime = Get-Date
    $storeWindow = $null
    
    do {
        $desktop = [System.Windows.Automation.AutomationElement]::RootElement
        $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, "Microsoft Store")
        $storeWindow = $desktop.FindFirst([System.Windows.Automation.TreeScope]::Children, $condition)
        if ($storeWindow -ne $null) { break }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $startTime.AddSeconds($timeout))

    if ($storeWindow -eq $null) {
        Write-LeftAligned "$FGRed$Char_RedCross Could not find Microsoft Store window$Reset"
        Write-Log -Message "Microsoft Store window not found" -Level WARNING
        return
    }
    
    Start-Sleep -Seconds 2
    
    $buttonFound = $false
    foreach ($buttonText in $buttonTexts) {
        $buttonCondition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $buttonText)
        $button = $storeWindow.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $buttonCondition)
        
        if ($button -ne $null) {
            $invokePattern = $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
            if ($invokePattern -ne $null) {
                $invokePattern.Invoke()
                Write-LeftAligned "$FGGreen$Char_HeavyCheck Successfully clicked '$buttonText'$Reset"
                $buttonFound = $true
                break
            }
        }
    }
    
    if (-not $buttonFound) {
        Write-LeftAligned "$FGDarkMagenta$Char_Warn Could not find update button$Reset"
        Write-Log -Message "Could not find update button in Store" -Level WARNING
    }
    
    trap {
        Write-LeftAligned "$FGRed$Char_RedCross UI Automation Error$Reset"
        Write-Log -Message "UI Automation Error in Store: $($_.Exception.Message)" -Level ERROR
        continue
    }
}

function Invoke-WinUpdateCheck {
    Write-Host "$FGDarkGray$([string]$Char_LightLine * 60)$Reset"
    Write-Centered "$Char_EnDash Windows Update CHECK $Char_EnDash" -Color "$Bold$FGCyan"
    Write-Host ""

    try {
        Add-Type -AssemblyName UIAutomationClient
        Add-Type -AssemblyName UIAutomationTypes
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Failed to load UI Automation assemblies$Reset"
        return
    }

    Write-LeftAligned "$FGGray Opening Windows Update settings...$Reset"
    Write-Log -Message "Attempting to open Windows Update settings" -Level INFO
    Start-Process "ms-settings:windowsupdate"
    
    # RESTORED: Name-based logic
    $targetButtons = @("Check for updates", "Download & install all", "Install all", "Restart now")
    
    $timeout = 10
    $startTime = Get-Date
    $settingsWindow = $null
    
    do {
        $desktop = [System.Windows.Automation.AutomationElement]::RootElement
        $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, "Settings")
        $settingsWindow = $desktop.FindFirst([System.Windows.Automation.TreeScope]::Children, $condition)
        if ($settingsWindow -ne $null) { break }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $startTime.AddSeconds($timeout))
    
    if ($settingsWindow -eq $null) {
        Write-LeftAligned "$FGRed$Char_RedCross Could not find Settings window$Reset"
        Write-Log -Message "Settings window not found" -Level WARNING
        return
    }
    
    Start-Sleep -Seconds 2
    
    $buttonFound = $false
    foreach ($text in $targetButtons) {
        $buttonCondition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $text)
        $button = $settingsWindow.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $buttonCondition)
        
        if ($button -ne $null) {
            $invokePattern = $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
            if ($invokePattern -ne $null) {
                $invokePattern.Invoke()
                Write-LeftAligned "$FGGreen$Char_HeavyCheck Successfully clicked '$text'$Reset"
                $buttonFound = $true
                break
            }
        }
    }
    
    if (-not $buttonFound) {
            Write-LeftAligned "$FGDarkMagenta$Char_Warn Could not find update buttons$Reset"
            Write-Log -Message "Could not find update buttons in Settings" -Level WARNING
    }
    
    trap {
        Write-LeftAligned "$FGRed$Char_RedCross UI Automation Error$Reset"
        Write-Log -Message "UI Automation Error in Settings: $($_.Exception.Message)" -Level ERROR
        continue
    }
}

# --- Main ---
Write-Header "Windows Update SET & SCAN"
Set-WUSettings
Show-WUStatus

# --- User Prompt ---
Invoke-COMUpdateCheck; Invoke-WingetUpdateCheck; Invoke-MSStoreUpdateCheck; Invoke-WinUpdateCheck; # Footer
Write-Host ""
Write-Boundary
$FooterText = "$Char_Copyright 2026, www.AIIT.support. All Rights Reserved."
Write-Centered "$FGCyan$FooterText$Reset"

# Exit Spacing
Write-Host ""









