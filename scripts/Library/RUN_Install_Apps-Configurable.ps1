#Requires -RunAsAdministrator
# file: Install-RequiredApps-Configurable.ps1
param(
    [ValidateSet('Desktop','Laptop','Auto')]
    [string]$DeviceType = 'Auto',
    [string]$ConfigPath = "$PSScriptRoot\Install_Apps-Config.json"
)

# --- [USER PREFERENCE] CLEAR SCREEN START ---

# --------------------------------------------

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# -------------------------------------------------------------------

<#
.SYNOPSIS
  Installs a list of required applications in a guided process (Configurable).
#>

function Write-Stamp {
  param([string]$Tag = "")
  # Output suppressed per user request
}

# --- PREREQUISITE CHECK ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-LeftAligned "$FGRed$Char_RedCross This script must be run with Administrator privileges.$Reset"
    Write-LeftAligned "$FGGray Right-click the script and select 'Run as administrator'.$Reset"
    Write-Stamp "Admin check failed"
    return
}

# --- START HEADER ---
Write-Header "APP INSTALLER"

# --- [NEW] CONFIGURE DEFENDER SETTINGS ---
Write-Host ""
Write-ScriptText "Attempting to disable 'Controlled Folder Access'..."
Write-Stamp "Disabling Controlled Folder Access"

try {
    # Disable Controlled Folder Access
    Set-MpPreference -EnableControlledFolderAccess Disabled -ErrorAction Stop
    
    # Verify the setting
    $newPrefs = Get-MpPreference
    if ($newPrefs.EnableControlledFolderAccess -eq 0) {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Controlled Folder Access has been disabled.$Reset"
        Write-Stamp "Controlled Folder Access disabled"
    } else {
        Write-LeftAligned "$FGDarkRed$Char_RedCross Failed to disable Controlled Folder Access.$Reset"
        Write-ScriptText "The current state is: $($newPrefs.EnableControlledFolderAccess). This may be set by Group Policy." $FGDarkMagenta
        Write-Stamp "Failed to disable Controlled Folder Access (State: $($newPrefs.EnableControlledFolderAccess))"
    }
} catch {
    Write-LeftAligned "$FGRed$Char_Warn [ERROR] An error occurred while trying to disable Controlled Folder Access:$Reset"
    Write-ScriptText $_.Exception.Message $FGRed
    Write-ScriptText "This is often because the setting is managed by Group Policy (GPO) or Intune." $FGDarkMagenta
    Write-Stamp "Error disabling Controlled Folder Access: $($_.Exception.Message)"
}
Write-Boundary $FGDarkGray
# --- [END NEW] ---

# --- SETTINGS ---
$MinWingetVersion = [version]'1.5.0'
$StartTime = Get-Date
$TranscriptLogPath = Join-Path -Path ($env:WinAutoLogDir) -ChildPath ("App-Install-Transcript-{0:yyyyMMdd-HHmmss}.txt" -f $StartTime)
$SummaryLogPath    = Join-Path -Path ($env:WinAutoLogDir) -ChildPath ("App-Install-Summary-{0:yyyyMMdd-HHmmss}.txt" -f $StartTime)
Start-Transcript -Path $TranscriptLogPath -Append | Out-Null
$Summary = [System.Collections.Generic.List[object]]::new()
$SoftSuccessCodes = @(0,3010,-2145124332,0x8024001E,0x8024200B)
$ScriptExitCode = 0

# --- CONFIGURATION LOADING ---
if (-not (Test-Path $ConfigPath)) {
    Write-Host ""
    Write-LeftAligned "$FGRed$Char_RedCross Configuration file not found at: $ConfigPath$Reset"
    Stop-Transcript
    return
}

try {
    $rawJson = Get-Content $ConfigPath -Raw | ConvertFrom-Json
} catch {
    Write-Host ""
    Write-LeftAligned "$FGRed$Char_RedCross Failed to parse JSON configuration.$Reset"
    Write-ScriptText $_.Exception.Message $FGRed
    Stop-Transcript
    return
}

# Helper to convert object to hashtable for compatibility
function Convert-ToHashTable {
    param($InputObject)
    $hash = @{}
    $InputObject.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }
    return $hash
}

$BaseApps = @()
if ($rawJson.BaseApps) {
    foreach ($item in $rawJson.BaseApps) {
        $BaseApps += (Convert-ToHashTable $item)
    }
}

$LaptopApps = @()
if ($rawJson.LaptopApps) {
    foreach ($item in $rawJson.LaptopApps) {
        $LaptopApps += (Convert-ToHashTable $item)
    }
}

Write-ScriptText "Loaded configuration from: $(Split-Path $ConfigPath -Leaf)" $FGGray
Write-ScriptText "Base Apps: $($BaseApps.Count) | Laptop Apps: $($LaptopApps.Count)" $FGGray

# --- FUNCTIONS ---
function Add-Tls {
  if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12|Tls13') {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 }
    catch {
      Write-Host "  $FGDarkMagenta Could not enable TLS 1.3, using TLS 1.2 only: $($_.Exception.Message)$Reset"
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
  }
}

function Test-AppConfiguration {
  [CmdletBinding()]
  param([Parameter(Mandatory)][hashtable]$App)
  $errors = @()
  if (-not $App.ContainsKey('AppName') -or [string]::IsNullOrWhiteSpace($App.AppName)) { $errors += "Missing required field: AppName" }
  if ($App.ContainsKey('IsPrerequisite') -and $App.IsPrerequisite) { return $true }
  if (-not $App.ContainsKey('Type')) { $errors += "Missing required field: Type for app '$($App.AppName)'" }
  if ($App.Type -eq 'WINGET' -and -not $App.ContainsKey('WingetId')) { $errors += "WINGET type requires WingetId for app '$($App.AppName)'" }
  if (($App.Type -eq 'MSI' -or $App.Type -eq 'EXE') -and -not ($App.ContainsKey('Url') -or $App.ContainsKey('Urls') -or $App.ContainsKey('InstallerPath'))) {
    $errors += "$($App.Type) type requires Url, Urls, or InstallerPath for app '$($App.AppName)'"
  }
  if ($errors.Count -gt 0) { Write-Error "Configuration errors:`n$($errors -join "`n")"; return $false }
  return $true
}

function Get-File {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Url,[Parameter(Mandatory)][string]$Out)
  Add-Tls
  Write-ScriptText "Downloading from: $Url" $FGGray
  for ($i=1; $i -le 3; $i++) {
    try {
      $ProgressPreference = 'SilentlyContinue'
      Invoke-WebRequest -Uri $Url -OutFile $Out -UseBasicParsing -ErrorAction Stop
      $ProgressPreference = 'Continue'
      if (Test-Path $Out) {
        $fileSize = (Get-Item $Out).Length
        Write-ScriptText "Download complete: $([math]::Round($fileSize/1MB,2)) MB" $FGGray
      }
      return
    } catch {
      if ($i -lt 3) { Write-ScriptText "Download attempt $i failed. Retrying in $($i*10) seconds..." $FGDarkMagenta; Start-Sleep -Seconds (10*$i) }
      else { throw "Download failed after 3 attempts: $($_.Exception.Message)" }
    }
  }
}

function Get-MsiUrlFromLanding {
  param([Parameter(Mandatory)][string]$LandingUrl)
  Add-Tls
  $html = Invoke-WebRequest -Uri $LandingUrl -UseBasicParsing -ErrorAction Stop
  $msi = ($html.Links | Where-Object { $_.href -match '\.msi($|\?)' } | Select-Object -First 1).href
  if (-not $msi) { throw "No MSI link found at: $LandingUrl" }
  if ($msi -notmatch '^https?://') {
    $uri = [Uri]$LandingUrl; $base = "$($uri.Scheme)://$($uri.Host)"
    $msi = if ($msi.StartsWith('/')) { "$base$msi" } else { "$base/$msi" }
  }
  return $msi
}

function Ensure-WingetSources {
  try {
    Write-ScriptText "Checking Windows Package Manager sources..." $FGDarkMagenta
    $null = Start-Process -FilePath "winget.exe" -ArgumentList @("source","update","--disable-interactivity") -Wait -PassThru -ErrorAction SilentlyContinue
    $en = Start-Process -FilePath "winget.exe" -ArgumentList @("source","enable","msstore","--disable-interactivity") -Wait -PassThru -ErrorAction SilentlyContinue
    if ($en -and $en.ExitCode -ne 0) {
      Start-Process -FilePath "winget.exe" -ArgumentList @("source","add","-n","msstore","-a","https://storeedgefd.dsx.mp.microsoft.com/v9.0","--disable-interactivity") -Wait -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "  $FGGreen$Char_HeavyCheck Winget sources ready.$Reset"
  } catch { Write-ScriptText "Winget source prep failed: $($_.Exception.Message)" $FGDarkMagenta }
}

function Assert-WingetVersion {
  param([Parameter(Mandatory)][version]$Minimum)
  $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
  if (-not $winget) { Write-Host "  $FGRed$Char_Cross Windows Package Manager (winget) not installed.$Reset"; return $false }
  try { $raw = & winget --version 2>$null; $verText = ($raw | Select-Object -First 1).ToString().Trim().TrimStart('v','V'); $ver = [version]$verText }
  catch { Write-Host "  $FGRed$Char_Cross Unable to determine winget version.$Reset"; return $false }
  if ($ver -lt $Minimum) { Write-Host "  $FGRed$Char_Cross winget $verText detected. Version $($Minimum.ToString()) or newer required.$Reset"; return $false }
  Write-Host "  $FGGreen$Char_HeavyCheck winget $verText OK.$Reset"
  return $true
}

function Test-AppInstalled {
  [CmdletBinding()]
  param([Parameter(Mandatory)][hashtable]$App)

  if ($App.ContainsKey('CheckMethod') -and $App.CheckMethod -eq 'Appx') {
    $name = if ($App.ContainsKey('AppxName') -and $App.AppxName) { $App.AppxName } elseif ($App.ContainsKey('MatchName') -and $App.MatchName) { $App.MatchName } else { $App.AppName }
    $pkg = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $name -or $_.PackageFamilyName -like "$name*" -or $_.Name -like "$name*" } | Select-Object -First 1
    return [bool]$pkg
  }

  if ($App.ContainsKey('CheckMethod') -and $App.CheckMethod -eq 'File') {
    $path = if ($App.ContainsKey('FilePath')) { $App['FilePath'] } else { $null }
    return ([bool]$path -and (Test-Path -Path $path))
  }

  $scope = if ($App.ContainsKey('RegistryScope')) { $App.RegistryScope } else { 'Machine' }
  $roots = @()
  if ($scope -eq 'Machine' -or $scope -eq 'All') {
    $roots += "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $roots += "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
  }
  if ($scope -eq 'User' -or $scope -eq 'All') {
    $roots += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $roots += "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
  }

  $pattern = if ($App.ContainsKey('MatchName')) { $App.MatchName } else { $App.AppName }
  foreach ($r in $roots) {
    if (-not (Test-Path $r)) { continue }
    foreach ($k in (Get-ChildItem $r -ErrorAction SilentlyContinue)) {
      $dn = $k.GetValue('DisplayName',$null)
      if ($dn -and ($dn -like $pattern)) { return $true }
    }
  }
  return $false
}

function Install-WithWingetRetry {
  param([Parameter(Mandatory)][hashtable]$App)
  $base = @("install","--id",$App.WingetId,"-e","--accept-package-agreements","--accept-source-agreements","--silent","--disable-interactivity")
  if ($App.ContainsKey('Source') -and $App.Source) { $base += @("--source",$App.Source) }

  # Attempt 1
  $args1 = @($base)
  if ($App.ContainsKey('WingetScope') -and $App.WingetScope) { $args1 += @("--scope",$App.WingetScope) }
  $p1 = Start-Process -FilePath "winget.exe" -ArgumentList $args1 -Wait -PassThru -ErrorAction SilentlyContinue
  $c1 = if ($null -ne $p1) { $p1.ExitCode } else { 0 }
  if ($c1 -eq 0) { return 0 }

  # Attempt 2
  try { Start-Process winget.exe -ArgumentList @("source","update","--disable-interactivity") -Wait -ErrorAction SilentlyContinue | Out-Null } catch {}
  $alt = if ($App.ContainsKey('WingetScope') -and $App.WingetScope -eq 'Machine') { 'User' } else { 'Machine' }
  $args2 = @($base) + @("--scope",$alt)
  $p2 = Start-Process -FilePath "winget.exe" -ArgumentList $args2 -Wait -PassThru -ErrorAction SilentlyContinue
  $c2 = if ($null -ne $p2) { $p2.ExitCode } else { 0 }
  if ($c2 -eq 0) { return 0 }

  Write-ScriptText "winget failed for {0}. Codes: first={1}, second={2}." -f $App.AppName,$c1,$c2 $FGDarkMagenta
  return $c2
}

function Wait-UntilDetected {
  param([Parameter(Mandatory)][hashtable]$App,[int]$TimeoutSec=150,[int]$IntervalSec=5)
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  do {
    if (Test-AppInstalled -App $App) { return $true }
    Start-Sleep -Seconds $IntervalSec
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Invoke-GenericInstall {
  [CmdletBinding()]
  param([Parameter(Mandatory)][hashtable]$App)
  $AppName = $App.AppName
  $InstallerType = $App.Type
  Write-Host ""
  Write-ScriptText "Starting installation for '$AppName' (Type: $InstallerType)..." $FGDarkCyan

  # [NEW] Pre-Installation Delay Support
  if ($App.ContainsKey('PreInstallDelay') -and $App.PreInstallDelay -gt 0) {
      Write-ScriptText "Waiting $($App.PreInstallDelay) seconds before installation as requested..." $FGDarkMagenta
      Start-Sleep -Seconds $App.PreInstallDelay
  }

  $tmp = $null; $exit = $null

  try {
    switch ($InstallerType) {
      "MSI" {
        $installerFilePath = $null
        if ($App.ContainsKey('InstallerPath') -and (Test-Path -Path $App.InstallerPath)) {
          $installerFilePath = $App.InstallerPath
          Write-ScriptText "Using network/local installer at: $installerFilePath" $FGGray
        } else {
          Write-ScriptText "Local installer not found. Attempting download..." $FGGray
          $urls = @()
          if ($App.ContainsKey('Urls')) { $urls = @($App.Urls) } elseif ($App.ContainsKey('Url')) { $urls = @($App.Url) }
          
          if ($urls.Count -eq 0) { throw "No URL(s) specified for MSI." }
          $resolvedUrl = $null
          foreach ($u in $urls) {
            try {
              if ($u -match '\.msi($|\?)|//aka\.ms/') { $resolvedUrl = $u } else { $resolvedUrl = Get-MsiUrlFromLanding -LandingUrl $u }
              break
            } catch { continue }
          }
          if (-not $resolvedUrl) { throw "Could not resolve a valid MSI URL." }
          $InstallerFileName = if ($App.ContainsKey('OutFileName')) { $App.OutFileName } else { [IO.Path]::GetFileName(([Uri]$resolvedUrl).AbsolutePath) }
          if ([string]::IsNullOrWhiteSpace($InstallerFileName)) { $InstallerFileName = "$($App.AppName.Replace(' ','-'))-installer.msi" }
          $installerFilePath = Join-Path -Path $env:TEMP -ChildPath $InstallerFileName
          Write-ScriptText "Downloading '$AppName' MSI..." $FGGray
          Get-File -Url $resolvedUrl -Out $installerFilePath
          $tmp = $installerFilePath
        }
        $msiArgs = "/i `"$installerFilePath`" /qn /norestart"
        if ($App.ContainsKey('MsiParams') -and $App.MsiParams) { $msiArgs += " $($App.MsiParams)" }
        $p = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -ErrorAction Stop
        $exit = $p.ExitCode
      }
      "EXE" {
        $installerFilePath = $null
        if ($App.ContainsKey('InstallerPath') -and (Test-Path -Path $App.InstallerPath)) {
          $installerFilePath = $App.InstallerPath
        } elseif ($App.ContainsKey('Url')) {
          $InstallerFileName = if ($App.ContainsKey('OutFileName')) { $App.OutFileName } else { [IO.Path]::GetFileName(([Uri]$App.Url).AbsolutePath) }
          if ([string]::IsNullOrWhiteSpace($InstallerFileName) -or $InstallerFileName -eq "files") { $InstallerFileName = "$($App.AppName.Replace(' ','-'))-installer.exe" }
          $installerFilePath = Join-Path -Path $env:TEMP -ChildPath $InstallerFileName
          Write-ScriptText "Downloading '$AppName' EXE..." $FGGray
          Get-File -Url $App.Url -Out $installerFilePath
          $tmp = $installerFilePath
        }
        else { throw "No valid InstallerPath or Url found." }
        $args = if ($App.ContainsKey('SilentArgs')) { $App.SilentArgs } else { "/quiet /norestart" }
        $p = Start-Process -FilePath $installerFilePath -ArgumentList $args -Wait -PassThru -ErrorAction Stop
        $exit = $p.ExitCode
      }
      "WINGET" {
        $exit = Install-WithWingetRetry -App $App
      }
      "BUILTIN" {
        Write-Host "  $FGGreen$Char_HeavyCheck '$AppName' is built into Windows.$Reset"
        $exit = 0
      }
      Default { throw "Unknown installer Type: $InstallerType" }
    }

    if ($null -eq $exit) { Write-ScriptText "Installer returned no exit code; treating as soft success." $FGDarkMagenta; $exit = 0 }
    if ($SoftSuccessCodes -notcontains $exit) { throw "Installer returned non-success exit code: $exit" }
  }
  catch {
    Write-Host "  $FGMagenta$Char_Warn [ERROR] '$AppName' installation failed.$Reset"
    Write-ScriptText "Details: $($_.Exception.Message)" $FGMagenta
    $finalExitCode = if ($null -ne $exit) { $exit } else { -1 }
    $Summary.Add([pscustomobject]@{ AppName = $AppName; Type = $InstallerType; Exit = $finalExitCode; Present = $false; Time = Get-Date })
    $global:ScriptExitCode = 1
    return
  }
  finally { if ($tmp -and (Test-Path $tmp)) { Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue } }

  $isUserCtx = (($App.ContainsKey('RegistryScope') -and $App.RegistryScope -eq 'User') -or (($App.ContainsKey('CheckMethod') -and $App.CheckMethod -eq 'Appx') -and ($App.ContainsKey('Source') -and $App.Source -eq 'msstore'))) -and ($App.WingetScope -ne 'Machine')

  $present = $false
  if ($isUserCtx) {
    Write-ScriptText "User-context install initiated. Verification deferred." $FGDarkMagenta
    $present = $true
  } else {
    $present = Wait-UntilDetected -App $App -TimeoutSec 150 -IntervalSec 5
    if ($present) { Write-Host "  $FGGreen$Char_HeavyCheck '$AppName' successfully installed.$Reset" }
    else { Write-Host "  $FGDarkMagenta$Char_Warn '$AppName' not detected after timeout.$Reset" }
  }

  $Summary.Add([pscustomobject]@{ AppName = $AppName; Type = $InstallerType; Exit = $exit; Present = [bool]$present; Time = Get-Date })
}

# --- DEVICE TYPE DETERMINATION ---
$IsDesktop = $false
if ($DeviceType -eq 'Desktop') { $IsDesktop = $true }
elseif ($DeviceType -eq 'Laptop') { $IsDesktop = $false }
else {
  try {
    $chassis = (Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes
    if ($chassis -and ($chassis -contains 3 -or $chassis -contains 4 -or $chassis -contains 5 -or $chassis -contains 6 -or $chassis -contains 7 -or $chassis -contains 15 -or $chassis -contains 23 -or $chassis -contains 31)) { $IsDesktop = $true }
  } catch {}
  Write-ScriptText "Auto-detected DeviceType: $(if($IsDesktop){'Desktop'}else{'Laptop'})" $FGDarkMagenta
}

# Compose final app list
$RequiredApps = [System.Collections.Generic.List[Object]]::new()
$RequiredApps.AddRange($BaseApps)
if (-not $IsDesktop) {
  # Add Laptop Apps from loaded config
  foreach ($app in $LaptopApps) {
      $RequiredApps.Add($app)
  }
  if ($LaptopApps.Count -gt 0) {
      Write-ScriptText "Additional modules included for Laptop." $FGDarkMagenta
  }
}

# --- MAIN SCRIPT BODY ---

Write-Host ""
Write-ScriptText "Validating app configurations..."
$configValid = $true
foreach ($app in $RequiredApps) { if (-not (Test-AppConfiguration -App $app)) { $configValid = $false } }
if (-not $configValid) { Write-Error "Configuration validation failed."; return }
Write-Host "  $FGGreen$Char_HeavyCheck Configuration validation passed.$Reset"
Write-Stamp "Config validated"

# Separate apps
$PrerequisiteApps = $RequiredApps | Where-Object { $_.ContainsKey('IsPrerequisite') -and $_.IsPrerequisite }
$StandardApps     = $RequiredApps | Where-Object { -not ($_.ContainsKey('IsPrerequisite') -and $_.IsPrerequisite) }

# --- GUIDED PREREQUISITE CHECK ---
while ($true) {
  Write-Host ""
  Write-ScriptText "--- Starting Security Prerequisite Check ---"
  $MissingPrereqs = [System.collections.Generic.List[object]]::new()

  foreach ($app in $PrerequisiteApps) {
    if (-not (Test-AppInstalled -App $app)) { $MissingPrereqs.Add($app) }
    else { Write-LeftAligned "$FGDarkGreen$Char_BallotCheck $($app.AppName): Found$Reset" }
  }

  if ($MissingPrereqs.Count -gt 0) {
    Write-ScriptText "The following security prerequisites are missing:" $FGDarkMagenta
    foreach ($app in $MissingPrereqs) {
      Write-LeftAligned "$FGDarkRed$Char_RedCross $($app.AppName)$Reset"
      if ($app.ContainsKey('ManualInstallPath')) { Write-ScriptText "   Path: $($app.ManualInstallPath)" $FGGray }
    }
        # Added Timeout Functionality
        $null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
      }
      else {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck All security prerequisites are met.$Reset"
        Write-Boundary $FGDarkGray
        break
      }
    }
    
    # --- STANDARD INSTALLATION ---
    if (-not (Assert-WingetVersion -Minimum $MinWingetVersion)) { Write-Stamp "winget too old"; return }
    Ensure-WingetSources
    
    Write-Host ""
    Write-LeftAligned "Starting check for required applications..."
    $AppsToInstall = @()
    $AlreadyPresentApps = [System.Collections.Generic.List[string]]::new()
    foreach ($app in $StandardApps) {
      if (Test-AppInstalled -App $app) {
        Write-LeftAligned "$FGDarkGreen$Char_BallotCheck Found: $($app.AppName)$Reset"
        $AlreadyPresentApps.Add($app.AppName)
      } else {
        Write-LeftAligned "$FGDarkRed$Char_RedCross Missing: $($app.AppName)$Reset"
        $AppsToInstall += $app
      }
    }
    
    Write-Host ""
    if ($AppsToInstall.Count -gt 0) {
      $AppsToInstall = $AppsToInstall | Sort-Object InstallOrder
      $selectionMap = @{}
      for ($i=0; $i -lt $AppsToInstall.Count; $i++) { $selectionMap[$i] = $true } # Default All
    
      $loop = $true
      while ($loop) {

          Write-Header "APP INSTALLER"
          Write-BodyTitle "SELECT APPS TO INSTALL"
          Write-Host ""
          
          for ($i=0; $i -lt $AppsToInstall.Count; $i++) {
              $app = $AppsToInstall[$i]
              $isSelected = $selectionMap[$i]
              $mark = if ($isSelected) { "$FGGreen$Char_BallotCheck$Reset" } else { "$FGRed$Char_RedCross$Reset" } # Visual check
              $idx = "$FGYellow[$($i+1)]$Reset"
              Write-LeftAligned "$idx $mark $($app.AppName)"
          }
          
          Write-Host ""
          Write-Boundary
          Write-Centered "${FGWhite}Type ${FGYellow}ID${FGWhite} to toggle ${FGDarkGray}|${FGWhite} ${FGYellow}A${FGWhite}ll ${FGDarkGray}|${FGWhite} ${FGYellow}N${FGWhite}one"
          
          $PromptCursorTop = [Console]::CursorTop
          $TickAction = {
              param($ElapsedTimespan)
              $WiggleFrame = [Math]::Floor($ElapsedTimespan.TotalMilliseconds / 500); $IsRight = ($WiggleFrame % 2) -eq 1
              $CurrentChars = if ($IsRight) { @(" ", $Char_Finger, "[", "E", "n", "t", "e", "r", "]", " ") } else { @($Char_Finger, " ", "[", "E", "n", "t", "e", "r", "]", " ") }
              $FilledCount = [Math]::Floor($ElapsedTimespan.TotalSeconds); if ($FilledCount -gt 10) { $FilledCount = 10 }
              $DynamicPart = ""
              for ($i = 0; $i -lt 10; $i++) {
                  $Char = $CurrentChars[$i]
                  if ($i -lt $FilledCount) { $DynamicPart += "${BGYellow}${FGBlack}$Char${Reset}" } else { $DynamicPart += if ($Char -eq " ") { " " } else { "${FGYellow}$Char${Reset}" } }
              }
              $p = "${FGWhite}$Char_Keyboard  Press ${FGDarkGray}$DynamicPart${FGDarkGray}${FGWhite}to${FGDarkGray} ${FGYellow}INSTALL${FGDarkGray} ${FGWhite}|${FGDarkGray} or Type Selection$Char_Skip${Reset}"
              try { [Console]::SetCursorPosition(0, $PromptCursorTop); Write-Centered $p } catch {}
          }
          
          $resKey = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
          Write-Host ""
          if ($resKey.VirtualKeyCode -eq 13) { $val = "" } else { $val = $resKey.Character.ToString() }
          
          if ([string]::IsNullOrWhiteSpace($val)) {
              $loop = $false # Proceed to install
          } elseif ($val -eq 'A' -or $val -eq 'a') {
              for ($i = 0; $i -lt $AppsToInstall.Count; $i++) { $selectionMap[$i] = $true }
          } elseif ($val -eq 'N' -or $val -eq 'n') {
              for ($i = 0; $i -lt $AppsToInstall.Count; $i++) { $selectionMap[$i] = $false }
          } elseif ($val -match '^\d+') {
              $idx = [int]$val - 1
              if ($selectionMap.ContainsKey($idx)) { $selectionMap[$idx] = -not $selectionMap[$idx] }
          } else {
              if ($val -match '^q|exit') {
                  Write-LeftAligned "Installation canceled." -ForegroundColor Yellow
                  Stop-Transcript
                  return
              }
          }
      }
    
      # Filter List based on Selection
      $SelectedApps = @()
      for ($i = 0; $i -lt $AppsToInstall.Count; $i++) {
          if ($selectionMap[$i]) { $SelectedApps += $AppsToInstall[$i] }
      }
    
      if ($SelectedApps.Count -eq 0) {
          Write-Host ""
          Write-LeftAligned "No applications selected. Exiting." -ForegroundColor Yellow
          Stop-Transcript
          return
      }
    
      Write-Boundary
      Write-LeftAligned "Installing $($SelectedApps.Count) applications..." -ForegroundColor Yellow
      Write-Stamp "Starting application installation"
      foreach ($app in $SelectedApps) { Invoke-GenericInstall -App $app }
    } else {
      Write-LeftAligned "$FGGreen$Char_HeavyCheck All required applications are already installed.$Reset"
    }
    
    # --- FINAL SUMMARY ---
    Stop-Transcript | Out-Null
    $logContent = [System.Collections.Generic.List[string]]::new()
    $logContent.Add("========================================")
    $logContent.Add(" App Installation Log")
    $logContent.Add("========================================")
    $logContent.Add("Date: $(Get-Date)")
    $logContent.Add("Computer: $env:COMPUTERNAME")
    $logContent.Add("User: $env:USERNAME")
    $logContent.Add("Generated by: WinAuto AI Auditor at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $logContent.Add("")
    
    # Wrap in arrays to avoid null .Count errors when no installs occurred
    $successes = @($Summary | Where-Object { $_.Present })
    $failures  = @($Summary | Where-Object { -not $_.Present })
    
    $logContent.Add("--- Successful Installations ($($successes.Count)) ---")
    if ($successes.Count -gt 0) { $successes | ForEach-Object { $logContent.Add("- $($_.AppName) (Exit Code: $($_.Exit))") } } else { $logContent.Add("None") }
    $logContent.Add("")
    
    $logContent.Add("--- Failed Installations ($($failures.Count)) ---")
    if ($failures.Count -gt 0) { $failures | ForEach-Object { $logContent.Add("- $($_.AppName) (Exit Code: $($_.Exit))") } } else { $logContent.Add("None") }
    $logContent.Add("")
    
    $logContent.Add("--- Already Installed ($($AlreadyPresentApps.Count)) ---")
    if ($AlreadyPresentApps.Count -gt 0) { $AlreadyPresentApps | ForEach-Object { $logContent.Add("- $_") } } else { $logContent.Add("None") }
    $logContent.Add("")
    $logContent.Add("========================================")
    $logContent.Add("End of Report")
    
    $logContent | Out-File -FilePath $SummaryLogPath -Encoding UTF8 -Force
    
    Write-Boundary
    Write-LeftAligned "All operations complete."
    Write-LeftAligned "Summary log: $SummaryLogPath"
    Write-LeftAligned "Transcript:  $TranscriptLogPath"
    Write-Stamp "Summary emitted"
    
    # --- [ADDED PER REQUEST] Wait before final verification ---
    Write-Host ""
    Write-LeftAligned "Waiting 10 seconds for services to settle before final verification..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    # --- [END ADDITION] ---
    
    # --- FINAL CONDITIONAL OUTPUT ---
    Write-Host ""
    Write-Boundary $FGDarkGray
    
    $StillMissingApps = [System.Collections.Generic.List[string]]::new()
    foreach ($app in $AppsToInstall) {
      if (-not (Test-AppInstalled -App $app)) {
        $isUserContextApp = (($app.ContainsKey('RegistryScope') -and $app.RegistryScope -eq 'User') -or
          (($app.ContainsKey('CheckMethod') -and $app.CheckMethod -eq 'Appx') -and ($app.ContainsKey('Source') -and $app.Source -eq 'msstore'))) -and
          ($app.WingetScope -ne 'Machine')
        if (-not $isUserContextApp) { $StillMissingApps.Add($app.AppName) }
      }
    }
    
    if ($StillMissingApps.Count -eq 0) {
      Write-LeftAligned "$FGGreen$Char_HeavyCheck All required applications successfully installed!$Reset"
    } else {
      Write-LeftAligned "$FGRed$Char_RedCross Required applications that still need to be installed:$Reset"
      $StillMissingApps | ForEach-Object { Write-LeftAligned "$FGRed - $_$Reset" -Indent 4 }
      Write-LeftAligned "See log for details: $TranscriptLogPath" -ForegroundColor Yellow
    }
    Write-Boundary $FGDarkGray
    Write-Stamp "Run complete"
    
    # --- [NEW] RE-ENABLE CONTROLLED FOLDER ACCESS ---
    Write-Host ""
    Write-LeftAligned "Attempting to re-enable 'Controlled Folder Access'..."
    Write-Stamp "Re-enabling Controlled Folder Access"
    
    try {
        # Enable Controlled Folder Access
        Set-MpPreference -EnableControlledFolderAccess Enabled -ErrorAction Stop
        
        # Verify the setting
        $newPrefs = Get-MpPreference
        if ($newPrefs.EnableControlledFolderAccess -eq 1) {
            Write-LeftAligned "$FGGreen$Char_HeavyCheck Controlled Folder Access has been re-enabled.$Reset"
            Write-Stamp "Controlled Folder Access enabled"
        } else {
            Write-LeftAligned "$FGRed$Char_RedCross Failed to re-enable Controlled Folder Access.$Reset"
            Write-LeftAligned "The current state is: $($newPrefs.EnableControlledFolderAccess). This may be set by Group Policy." -ForegroundColor Yellow
            Write-Stamp "Failed to re-enable Controlled Folder Access (State: $($newPrefs.EnableControlledFolderAccess))"
        }
    } catch {
        Write-LeftAligned "$FGRed$Char_Warn [ERROR] An error occurred while trying to re-enable Controlled Folder Access:$Reset"
        Write-LeftAligned $_.Exception.Message -ForegroundColor Red
        Write-LeftAligned "This is often because the setting is managed by Group Policy (GPO) or Intune." -ForegroundColor Yellow
        Write-Stamp "Error re-enabling Controlled Folder Access: $($_.Exception.Message)"
    }
    Write-Boundary $FGDarkGray
    # --- [END NEW] ---
    
    # --- COPYRIGHT FOOTER ---
    Write-Host ""
    Write-Boundary
    $FooterText = "$Char_Copyright 2026, www.AIIT.support. All Rights Reserved."
    Write-Centered "$FGCyan$FooterText$Reset"
    
    # --- EXIT CODE POLICY ---
    $rebootMatches = @($Summary | Where-Object { $_.Exit -eq 3010 })
    
    if ($ScriptExitCode -ne 0) {
        # Failure already occurred and set the exit code to 1
    } elseif ($rebootMatches.Count -gt 0) {
        $ScriptExitCode = 3010 # Reboot needed
    }
    
    # --- [USER PREFERENCE] END OF SCRIPT PADDING ---
    Write-Host ""
    # -----------------------------------------------







