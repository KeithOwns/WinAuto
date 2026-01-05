#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Comprehensive Windows Security Status Checker with Reporting and Remediation
.DESCRIPTION
    Retrieves and displays all Windows Security configurations with visual formatting,
    security scoring, and remediation suggestions.
    
    STRICTLY MATCHED TO scriptRULES-W11.ps1 STANDARDS.
    - Header: Cyan 'WinAuto' / DarkCyan Subtitle / DarkBlue Boundary
    - Body: Left-Aligned, 1 Space Indent
    - Icons: System Enabled (DarkGreen Ballot), System Disabled (DarkRed XSquare 0x274E)
    - Boundaries: Body (DarkGray), Header/Footer (DarkBlue)
    - Footer: Copyright 2026, All Rights Reserved (Cyan)
    - Colors: Body Text (Gray), Header Icons (White), Output Text (DarkCyan)
    - Version Check: Compares local signature against Microsoft Online (DarkGreen/DarkRed)

.PARAMETER ShowRemediation
    Display PowerShell commands to fix disabled security features
.NOTES
    Requires Administrator privileges
    Encoding: UTF-8
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$ShowRemediation,
    [switch]$AutoRun
)

# --- [USER PREFERENCE] CLEAR SCREEN START ---

# --------------------------------------------

# --- FIX: Reset environment settings to prevent conflicts ---
Set-StrictMode -Off
$ErrorActionPreference = 'Continue'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- LOGGING SETUP ---
. "$PSScriptRoot\MODULE_Logging.ps1"
Init-Logging


# --- Unified Helper Functions ---

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
        if (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord -Force | Out-Null
        } else {
            New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
        }
        Write-Log -Message "Set registry: $Path\$Name = $Value" -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to set registry: $Path\$Name - $($_.Exception.Message)" -Level ERROR
        throw $_ 
    }
}

# NEW: Set-RegistryString to handle text-based registry values (like SmartScreen)
function Set-RegistryString {
    param([Parameter(Mandatory)] [string]$Path, [Parameter(Mandatory)] [string]$Name, [Parameter(Mandatory)] [string]$Value)
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-Log -Message "Created registry path: $Path" -Level INFO
        }
        New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
        Write-Log -Message "Set registry string: $Path\$Name = $Value" -Level SUCCESS
    } catch {
        Write-Log -Message "Failed to set registry: $Path\$Name - $($_.Exception.Message)" -Level ERROR
        throw $_
    }
}

# --- Script 02 Specific Helpers ---

# Global variables
$script:SecurityChecks = @()
$script:RealTimeProtectionEnabled = $true
$script:ThirdPartyAVActive = $false
$script:ScanStatusAllGreen = $false
$script:ActiveThreatCount = 0
$script:FullScanNeeded = $false

class SecurityCheck {
    [string]$Category
    [string]$Name
    [bool]$IsEnabled
    [string]$Severity
    [string]$Remediation
    [string]$Details
}

function Add-SecurityCheck {
    param(
        [string]$Category, [string]$Name, [bool]$IsEnabled, 
        [string]$Severity = "Warning", [string]$Remediation = "", [string]$Details = ""
    )
    $check = [SecurityCheck]@{
        Category = $Category; Name = $Name; IsEnabled = $IsEnabled; 
        Severity = $Severity; Remediation = $Remediation; Details = $Details
    }
    $script:SecurityChecks += $check
}

function Write-SectionHeader {
    param(
        [string]$Title, 
        [string]$Icon = $Char_Shield, 
        [string]$IconColor = $FGWhite, 
        [int]$Gap = 2,
        [switch]$IsFirstSection, 
        [switch]$NoBoundary 
    )
    # 1. DarkGray Boundary (Only if not suppressed)
    if (-not $NoBoundary) {
        Write-Host "$FGDarkGray$([string]$Char_LightLine * 60)$Reset"
    }
    
    # 2. Windows Security (Only for First Section)
    if ($IsFirstSection) {
        Write-LeftAligned "$FGWhite Windows Security$Reset"
        Write-Host ""
    }
    
    # 4. Icon + Title (White)
    $Spacing = " " * $Gap
    Write-Host ("  $IconColor$Icon$Spacing$FGWhite$Title$Reset")
}

# --- Auditing Functions ---

function Get-ThirdPartyAntivirus {
    try {
        $antivirusProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction Stop
        foreach ($av in $antivirusProducts) {
            if ($av.displayName -notmatch "Defender|Windows Security") {
                if ($av.productState) { return [PSCustomObject]@{ IsThirdParty = $true; ProductName = $av.displayName } }
            }
        }
        return [PSCustomObject]@{ IsThirdParty = $false; ProductName = "Windows Defender" }
    } catch {
        return [PSCustomObject]@{ IsThirdParty = $false; ProductName = "Windows Defender" }
    }
}

function Get-DefenderStatus {
    Write-SectionHeader "Virus & threat protection" -Icon $Char_Shield -Gap 2 -IsFirstSection -NoBoundary

    $avInfo = Get-ThirdPartyAntivirus
    if ($avInfo.IsThirdParty) {
        Write-LeftAligned "$Char_Warn Managed by: $($avInfo.ProductName)" -Indent 3
        $script:RealTimeProtectionEnabled = $false
        $script:ThirdPartyAVActive = $true
        Add-SecurityCheck -Category "Virus & Threat Protection" -Name "Third-party antivirus" -IsEnabled $true -Severity "Info" -Details "Managed by: $($avInfo.ProductName)"
        Write-Log -Message "Third-party AV detected: $($avInfo.ProductName)" -Level INFO
        return
    }

    try { $preferences = Get-MpPreference -ErrorAction Stop } catch {
        Write-LeftAligned "$FGDarkRed$Char_XSquare Unable to retrieve Defender settings$Reset" -Indent 3
        Write-Log -Message "Failed to retrieve Defender preferences" -Level ERROR
        return
    }

    $realTimeOff = $preferences.DisableRealtimeMonitoring
    $script:RealTimeProtectionEnabled = !$realTimeOff
    $enabled = !$realTimeOff
    Write-LeftAligned (Get-StatusLine $enabled "Real-time protection") -Indent 3
    Add-SecurityCheck -Category "Virus & Threat Protection" -Name "Real-time protection" -IsEnabled $enabled -Severity "Critical" -Remediation "Set-MpPreference -DisableRealtimeMonitoring `$false"

    if (!$enabled) { Write-LeftAligned "$FGDarkMagenta$Char_Warn Dependencies disabled$Reset" -Indent 3 }
    
    $enabled = !$preferences.DisableDevDriveScanning
    Write-LeftAligned (Get-StatusLine $enabled "Dev Drive protection") -Indent 3
    Add-SecurityCheck -Category "Virus & Threat Protection" -Name "Dev Drive protection" -IsEnabled $enabled -Severity "Info" -Remediation "Set-MpPreference -DisableDevDriveScanning `$false"

    $enabled = $preferences.MAPSReporting -ne 0
    Write-LeftAligned (Get-StatusLine $enabled "Cloud-delivered protection") -Indent 3
    Add-SecurityCheck -Category "Virus & Threat Protection" -Name "Cloud-delivered protection" -IsEnabled $enabled -Severity "Warning" -Remediation "Set-MpPreference -MAPSReporting Advanced"

    $enabled = $preferences.SubmitSamplesConsent -ne 0
    Write-LeftAligned (Get-StatusLine $enabled "Automatic sample submission") -Indent 3
    Add-SecurityCheck -Category "Virus & Threat Protection" -Name "Automatic sample submission" -IsEnabled $enabled -Severity "Warning" -Remediation "Set-MpPreference -SubmitSamplesConsent SendAllSamples"

    try {
        $tamperProtection = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -ErrorAction Stop
        $enabled = ($tamperProtection -eq 1 -or $tamperProtection -eq 5)
        
        if ($enabled) {
            Write-LeftAligned (Get-StatusLine $enabled "Tamper protection") -Indent 3
        } else {
            Write-LeftAligned "$FGDarkRed$Char_XSquare $FGDarkRed Tamper protection$Reset" -Indent 3
        }
        Add-SecurityCheck -Category "Virus & Threat Protection" -Name "Tamper protection" -IsEnabled $enabled -Severity "Critical" -Remediation "Enable via Windows Security UI"
    } catch {
        Write-LeftAligned "$FGDarkRed$Char_XSquare $FGGray Tamper protection (Unknown)$Reset" -Indent 3
        Add-SecurityCheck -Category "Virus & Threat Protection" -Name "Tamper protection" -IsEnabled $false -Severity "Critical"
    }

    if ($script:RealTimeProtectionEnabled) {
        $cfaEnabled = $preferences.EnableControlledFolderAccess -eq 1
        Write-LeftAligned (Get-StatusLine $cfaEnabled "Controlled folder access") -Indent 3
        Add-SecurityCheck -Category "Virus & Threat Protection" -Name "Controlled folder access" -IsEnabled $cfaEnabled -Severity "Warning" -Remediation "Set-MpPreference -EnableControlledFolderAccess Enabled"
    }
}

function Get-AccountProtection {
    Write-SectionHeader "Account protection" -Icon $Char_Person -Gap 1 -NoBoundary
    
    $helloConfigured = $false
    try { if (@(Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WinBio\AccountInfo" -ErrorAction SilentlyContinue).Count -gt 0) { $helloConfigured = $true } } catch {}
    
    Write-LeftAligned (Get-StatusLine $helloConfigured "Windows Hello") -Indent 3
    Add-SecurityCheck -Category "Account Protection" -Name "Windows Hello" -IsEnabled $helloConfigured -Severity "Warning" -Remediation "Configure via Settings > Accounts"

    $dynamicLockEnabled = (Get-RegistryValue "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" "EnableGoodbye") -eq 1
    Write-LeftAligned (Get-StatusLine $dynamicLockEnabled "Dynamic lock") -Indent 3
    Add-SecurityCheck -Category "Account Protection" -Name "Dynamic lock" -IsEnabled $dynamicLockEnabled -Severity "Info" -Remediation "Configure via Settings > Accounts"
}

function Get-FirewallStatus {
    Write-SectionHeader "Firewall & network protection" -Icon $Char_Satellite -Gap 1 -NoBoundary

    $activeNetworks = @{}
    try {
        Get-NetConnectionProfile | ForEach-Object { $activeNetworks[$_.NetworkCategory] = $_.Name }
    } catch {}

    $profiles = @{ 'Domain'='DomainAuthenticated'; 'Private'='Private'; 'Public'='Public' }
    foreach ($p in $profiles.Keys) {
        try {
            $fw = Get-NetFirewallProfile -Name $p -ErrorAction Stop
            $enabled = $fw.Enabled
            $suffix = if ($activeNetworks[$profiles[$p]]) { " ($($activeNetworks[$profiles[$p]]))" } else { "" }
            Write-LeftAligned (Get-StatusLine $enabled "$p network firewall$suffix") -Indent 3
            Add-SecurityCheck -Category "Firewall" -Name "$p network firewall" -IsEnabled $enabled -Severity "Critical" -Remediation "Set-NetFirewallProfile -Profile $p -Enabled True"
        } catch {}
    }

    try {
        $netshOutput = netsh wlan show interfaces | Select-String -Pattern "Authentication"
        if ($netshOutput) {
            $authMethod = ($netshOutput -split ':')[-1].Trim()
            $isUnsecured = ($authMethod -match "Open|None|Unsecured" -and $authMethod -notmatch "WPA2-Open")
            
            if ($isUnsecured) {
                Write-LeftAligned "$FGDarkRed$Char_XSquare $FGDarkCyan Wi-Fi Security (UNSECURED: $authMethod)$Reset" -Indent 3
                Add-SecurityCheck -Category "Network" -Name "Wi-Fi Security" -IsEnabled $false -Severity "Warning" -Remediation "Connect to secured network"
                Write-Log -Message "Unsecured Wi-Fi detected: $authMethod" -Level WARNING
            } else {
                Write-LeftAligned "$FGDarkGreen$Char_BallotCheck $FGGray Wi-Fi Security ($authMethod)$Reset" -Indent 3
                Add-SecurityCheck -Category "Network" -Name "Wi-Fi Security" -IsEnabled $true -Severity "Info"
            }
        }
    } catch {}
}

function Get-ReputationProtection {
    Write-SectionHeader "App & browser control" -Icon $Char_CardIndex -Gap 2 -NoBoundary

    $smartScreenEnabled = (Get-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen") -eq 1
    if (-not $smartScreenEnabled) {
        $val = Get-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled"
        $smartScreenEnabled = ($val -ne "Off")
    }
    
    Write-LeftAligned (Get-StatusLine $smartScreenEnabled "Check apps and files") -Indent 3
    Add-SecurityCheck -Category "App Control" -Name "Check apps and files" -IsEnabled $smartScreenEnabled -Severity "Warning" -Remediation "Set SmartScreenEnabled to Warn"

    $edgeEnabled = $true 
    $val = Get-RegistryValue "HKCU:\Software\Microsoft\Edge\SmartScreenEnabled" "(default)"
    if ($val -ne $null -and $val -eq 0) { $edgeEnabled = $false }
    
    Write-LeftAligned (Get-StatusLine $edgeEnabled "SmartScreen for Edge") -Indent 3
    Add-SecurityCheck -Category "App Control" -Name "SmartScreen for Microsoft Edge" -IsEnabled $edgeEnabled -Severity "Warning" -Remediation "Enable Edge SmartScreen"

    if ($script:RealTimeProtectionEnabled) {
        try { $pua = (Get-MpPreference).PUAProtection -eq 1 } catch { $pua = $false }
        Write-LeftAligned (Get-StatusLine $pua "Potentially unwanted app blocking") -Indent 3
        Add-SecurityCheck -Category "App Control" -Name "Potentially unwanted app blocking" -IsEnabled $pua -Severity "Warning" -Remediation "Set-MpPreference -PUAProtection Enabled"
    }
}

function Get-CoreIsolationStatus {
    Write-SectionHeader "Device security" -Icon $Char_Desktop -Gap 2 -NoBoundary

    $memInt = (Get-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled") -eq 1
    
    Write-LeftAligned (Get-StatusLine $memInt "Memory integrity") -Indent 3
    Add-SecurityCheck -Category "Device Security" -Name "Memory integrity" -IsEnabled $memInt -Severity "Warning" -Remediation "Enable via Security Settings"

    $lsa = (Get-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RunAsPPL") -ge 1
    
    Write-LeftAligned (Get-StatusLine $lsa "Local Security Authority protection") -Indent 3
    Add-SecurityCheck -Category "Device Security" -Name "Local Security Authority protection" -IsEnabled $lsa -Severity "Warning" -Remediation "Set RunAsPPL to 1"

    $vdb = $true
    try { if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config" "VulnerableDriverBlocklistEnable" -ErrorAction SilentlyContinue).VulnerableDriverBlocklistEnable -eq 0) { $vdb = $false } } catch {}
    
    Write-LeftAligned (Get-StatusLine $vdb "Microsoft Vulnerable Driver Blocklist") -Indent 3
    Add-SecurityCheck -Category "Device Security" -Name "Microsoft Vulnerable Driver Blocklist" -IsEnabled $vdb -Severity "Warning" -Remediation "Enable VulnerableDriverBlocklist"
}

# --- NEW: Online Version Check Helper ---
function Get-OnlineDefenderVersion {
    try {
        $url = "https://www.microsoft.com/en-us/wdsi/definitions/antimalware-definitions-release-notes"
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        
        if ($response.Content -match 'Version:</b>\s*([0-9\.]+)') {
            return $matches[1]
        }
        return $null
    } catch {
        return $null
    }
}

function Get-ScanInformation {
    Write-SectionHeader "Current threats" -Icon $Char_Loop -Gap 1 -NoBoundary

    $status = Get-MpComputerStatus
    $now = Get-Date
    $threats = @(Get-MpThreat -ErrorAction SilentlyContinue)
    $script:ActiveThreatCount = $threats.Count
    
    $qsColor = if ($status.QuickScanStartTime -and ($now - $status.QuickScanStartTime).Days -lt 7) { $FGDarkGreen } else { $FGRed }
    $fsColor = if ($status.FullScanStartTime -and ($now - $status.FullScanStartTime).Days -lt 30) { $FGDarkGreen } else { $FGRed }
    $updColor = if ($status.AntivirusSignatureLastUpdated -and ($now - $status.AntivirusSignatureLastUpdated).Days -lt 7) { $FGDarkGreen } else { $FGRed }

    $script:ScanStatusAllGreen = ($qsColor -eq $FGDarkGreen) -and ($fsColor -eq $FGDarkGreen) -and ($updColor -eq $FGDarkGreen) -and ($script:ActiveThreatCount -eq 0)

    if ($fsColor -eq $FGRed) {
        $script:FullScanNeeded = $true
    }

    $LabelWidth = 17 
    $Indent = 7

    $threatColor = if ($script:ActiveThreatCount -eq 0) { $FGDarkGreen } else { $FGRed }
    $threatLabel = "Threats found"
    Write-LeftAligned "$FGGray$($threatLabel.PadRight($LabelWidth)):$Reset $threatColor$($script:ActiveThreatCount)$Reset" -Indent $Indent
    
    $qsLabel = "Last quick scan"
    $qsTime = if ($status.QuickScanStartTime) { $status.QuickScanStartTime.ToString('yyyy-MM-dd HH:mm') } else { "Never" }
    Write-LeftAligned "$FGGray$($qsLabel.PadRight($LabelWidth)): $qsColor$qsTime$Reset" -Indent $Indent

    $fsLabel = "Last full scan"
    $fsTime = if ($status.FullScanStartTime) { $status.FullScanStartTime.ToString('yyyy-MM-dd HH:mm') } else { "Never" }
    Write-LeftAligned "$FGGray$($fsLabel.PadRight($LabelWidth)): $fsColor$fsTime$Reset" -Indent $Indent
    
    $sigLabel = "Signature version"
    $installedVer = $status.AntivirusSignatureVersion
    $onlineVer = Get-OnlineDefenderVersion
    
    $sigColor = $FGWhite 
    if ($onlineVer) {
        try {
            $vInstalled = [version]$installedVer
            $vOnline = [version]$onlineVer
            if ($vInstalled -ge $vOnline) {
                $sigColor = $FGDarkGreen
            } else {
                $sigColor = $FGDarkRed
            }
        } catch {
            $sigColor = $FGWhite 
        }
    } else {
        if ($installedVer) { $sigColor = $FGDarkGreen }
    }
    
    Write-LeftAligned "$FGGray$($sigLabel.PadRight($LabelWidth)): $sigColor$installedVer$Reset" -Indent $Indent
    
    $updLabel = "Last updated"
    $updTime = if ($status.AntivirusSignatureLastUpdated) { $status.AntivirusSignatureLastUpdated.ToString('yyyy-MM-dd HH:mm') } else { "Never" }
    Write-LeftAligned "$FGGray$($updLabel.PadRight($LabelWidth)): $updColor$updTime$Reset" -Indent $Indent

    Write-Host "$FGDarkGray$([string]$Char_LightLine * 60)$Reset"
}

function Show-SecuritySummary {
    $disabled = ($script:SecurityChecks | Where-Object { !$_.IsEnabled }).Count
    $critical = ($script:SecurityChecks | Where-Object { !$_.IsEnabled -and $_.Severity -eq "Critical" }).Count
    
    Write-Host ""
    
    $ReportTitle = "$Char_EnDash Windows Security REPORT $Char_EnDash"
    Write-Centered "$FGCyan$ReportTitle$Reset"
    
    Write-Host ""

    if ($disabled -eq 0) {
        $text1 = "$Char_HeavyCheck All security features are enabled"
        Write-Centered "$FGGreen$text1$Reset"
        
        Write-Host ""

        if ($script:ActiveThreatCount -eq 0) {
            $text2 = "$Char_HeavyCheck No current threats"
            Write-Centered "$FGGreen$text2$Reset"
        } else {
            Write-Centered "$FGRed$Char_Warn $script:ActiveThreatCount threats found$Reset"
        }
    } else {
        Write-Centered "$FGRed$Char_RedCross $disabled disabled security features found$Reset"
        Write-Boundary $FGDarkBlue
        if ($critical -gt 0) {
            Write-Centered "$FGRed$Char_Radioactive  $critical Critical$Reset"
        }
    }
    Write-Boundary $FGDarkBlue
}

# --- Remediation & Application ---

function Enable-RealTimeProtection { try { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop; Write-Log "Enabled RealTimeProtection" "SUCCESS"; $true } catch { Write-Log "Failed RealTimeProtection" "ERROR"; $false } }
function Enable-CloudDeliveredProtection { try { Set-MpPreference -MAPSReporting Advanced -ErrorAction Stop; Write-Log "Enabled MAPSReporting" "SUCCESS"; $true } catch { Write-Log "Failed MAPSReporting" "ERROR"; $false } }
function Enable-AutomaticSampleSubmission { try { Set-MpPreference -SubmitSamplesConsent SendAllSamples -ErrorAction Stop; Write-Log "Enabled SampleSubmission" "SUCCESS"; $true } catch { Write-Log "Failed SampleSubmission" "ERROR"; $false } }
function Enable-ControlledFolderAccess { try { Set-MpPreference -EnableControlledFolderAccess Enabled -ErrorAction Stop; Write-Log "Enabled ControlledFolderAccess" "SUCCESS"; $true } catch { Write-Log "Failed ControlledFolderAccess" "ERROR"; $false } }
function Enable-PUAProtection { try { Set-MpPreference -PUAProtection Enabled -ErrorAction Stop; Write-Log "Enabled PUAProtection" "SUCCESS"; $true } catch { Write-Log "Failed PUAProtection" "ERROR"; $false } }
function Enable-MemoryIntegrity { try { Set-RegistryDword "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" 1; $true } catch { $false } }
function Enable-LSAProtection { try { Set-RegistryDword "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RunAsPPL" 1; $true } catch { $false } }
function Enable-Firewall { param($Profile) try { Set-NetFirewallProfile -Name $Profile -Enabled True -ErrorAction Stop; Write-Log "Enabled $Profile firewall" "SUCCESS"; $true } catch { Write-Log "Failed $Profile firewall" "ERROR"; $false } }
function Enable-CheckAppsAndFiles { try { Set-RegistryString "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "SmartScreenEnabled" "Warn"; $true } catch { $false } } 
function Enable-SmartScreenEdge { try { Set-RegistryDword "HKCU:\Software\Microsoft\Edge\SmartScreenEnabled" "(default)" 1; $true } catch { $false } }

function Restart-SecHealthUI {
    Write-LeftAligned "$FGDarkCyan Restarting Windows Security App...$Reset" -Indent 3
    Write-Log "Restarting Windows Security App" "INFO"
    
    # Stop Processes
    foreach ($proc in @("SecurityHealthSystray", "SecHealthUI")) {
        Get-Process $proc -ErrorAction SilentlyContinue | Stop-Process -Force
    }
    Start-Sleep -Seconds 1

    # Start App with Fallback
    try {
        Start-Process "windowsdefender:" -ErrorAction Stop
    } catch {
        Write-Log "Standard launch failed ($($_.Exception.Message)), using Explorer fallback." "WARNING"
        try {
            Start-Process "explorer.exe" -ArgumentList "windowsdefender:"
        } catch {
            Write-LeftAligned "$FGRed Failed to restart Security App.$Reset" -Indent 3
            Write-Log "Failed to restart Security App: $($_.Exception.Message)" "ERROR"
        }
    }
}

function Create-RestorePoint {
    Write-LeftAligned "$FGYellow Creating System Restore Point...$Reset" -Indent 3
    try {
        Checkpoint-Computer -Description "WinAuto Security Config $(Get-Date -Format 'yyyyMMdd_HHmm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-LeftAligned "$FGGreen$Char_BallotCheck Restore Point created.$Reset" -Indent 3
        Write-Log "Restore Point created" "SUCCESS"
    } catch {
        Write-LeftAligned "$FGRed$Char_Warn Skip Restore Point: $($_.Exception.Message)$Reset" -Indent 3
        Write-Log "Restore Point failed: $($_.Exception.Message)" "WARNING"
    }
}

function Apply-SecuritySettings {
    Create-RestorePoint
    $disabledChecks = $script:SecurityChecks | Where-Object { !$_.IsEnabled }
    $applied = 0
    Write-Log "Attempting to apply $($disabledChecks.Count) security settings" "INFO"

    foreach ($check in $disabledChecks) {
        $result = $false
        switch ($check.Name) {
            "Real-time protection" { $result = Enable-RealTimeProtection }
            "Cloud-delivered protection" { $result = Enable-CloudDeliveredProtection }
            "Automatic sample submission" { $result = Enable-AutomaticSampleSubmission }
            "Controlled folder access" { $result = Enable-ControlledFolderAccess }
            "Potentially unwanted app blocking" { $result = Enable-PUAProtection }
            "Memory integrity" { $result = Enable-MemoryIntegrity }
            "Local Security Authority protection" { $result = Enable-LSAProtection }
            "Domain network firewall" { $result = Enable-Firewall "Domain" }
            "Private network firewall" { $result = Enable-Firewall "Private" }
            "Public network firewall" { $result = Enable-Firewall "Public" }
            "Check apps and files" { $result = Enable-CheckAppsAndFiles }
            "SmartScreen for Microsoft Edge" { $result = Enable-SmartScreenEdge }
        }
        if ($result) { $applied++ }
    }
    
    if ($applied -gt 0) { 
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Enabled $applied features$Reset" -Indent 3
        Write-Log "Successfully enabled $applied features" "SUCCESS"
        Restart-SecHealthUI
    }
}

function Invoke-ApplySecuritySettings {
    if ($AutoRun) {
        $res = [PSCustomObject]@{ VirtualKeyCode = 13 }
    } else {
        $res = Invoke-AnimatedPause -ActionText "ENABLE" -Timeout 15
    }

    if ($res.VirtualKeyCode -eq 13) {
        Write-Boundary
        Write-Centered "$FGDarkCyan$Char_EnDash Security Features ENABLE $Char_EnDash$Reset"
        
        Apply-SecuritySettings
        Write-LeftAligned "$FGGreen Settings applied.$Reset" -Indent 3
        Write-Boundary
    } else { 
        Write-Host "`n"
        Write-LeftAligned "$FGGray Skipped application.$Reset" -Indent 3
        Write-Log "User skipped applying settings" "INFO"
    }
}

# --- Main Execution ---

try {
    Write-Header "WINDOWS SECURITY CONFIGURATOR"
    
    Write-Centered "$Char_EnDash Windows Security CHECK $Char_EnDash"
    Write-Boundary

    Write-Log "Security Check Started" "INFO"
    
    Get-DefenderStatus
    Get-AccountProtection
    Get-FirewallStatus
    Get-ReputationProtection
    Get-CoreIsolationStatus
    
    # Skip scan history if using 3rd party AV
    if (-not $script:ThirdPartyAVActive) {
        Get-ScanInformation
    }
    
    Show-SecuritySummary
    
    if ($ShowRemediation -or $AutoRun) {
        Invoke-ApplySecuritySettings
    }
    
    # Report
    Get-LogReport
    
    $FooterText = "$Char_Copyright 2026, www.AIIT.support. All Rights Reserved."

    Write-Centered "$FGCyan$FooterText$Reset"
    
    Write-Host ""

} catch {
    Write-Host "`n$FGRed[ERROR] $($_.Exception.Message)$Reset"
    Write-Log "Fatal Error: $($_.Exception.Message)" "ERROR"
    exit 1
}







