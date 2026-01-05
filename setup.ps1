<#
.SYNOPSIS
    WinAuto One-Liner Bootstrapper
.DESCRIPTION
    Downloads, installs, and launches the WinAuto suite.
    - Checks/Installs Git
    - Clones Repository
    - Creates Desktop Shortcut
    - Launches Suite
#>

# --- CONFIGURATION ---
# Params removed to support 'iex (irm ...)' invocation
$InstallDir = "$env:USERPROFILE\Documents\WinAuto"
$RepoURL = "https://github.com/KeithOwns/WinAuto.git"

# --- SETUP ANSI COLORS ---
$Esc = [char]0x1B
$Green = "$Esc[92m"; $Red = "$Esc[91m"; $Cyan = "$Esc[96m"; $Yellow = "$Esc[93m"; $Reset = "$Esc[0m"

function Write-Step { param($T) Write-Host " $Cyan[SETUP]$Reset $T" }
function Write-Ok   { param($T) Write-Host " $Green[OK]$Reset    $T" }
function Write-Err  { param($T) Write-Host " $Red[ERR]$Reset   $T" }

# Helper to print padding before exit
function Close-Script {
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    exit
}

Clear-Host
Write-Host ""
Write-Host " $Cyan   WinAuto Installer $Reset"
Write-Host " $Cyan   ================= $Reset"
Write-Host ""

# 1. CHECK ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "Administrator privileges required."
    Start-Sleep -Seconds 2
    Close-Script
}

# 2. CHECK GIT
Write-Step "Checking dependencies..."
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Ok "Git is installed."
} else {
    Write-Step "Git not found. Attempting installation via Winget..."
    try {
        winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
        Write-Ok "Git installed. (Note: You may need to restart the script if git is not found immediately)"
    } catch {
        Write-Err "Failed to install Git. Please install Git manually and retry."
        Close-Script
    }
}

# 3. CLONE / UPDATE REPO
Write-Step "Configuring installation path: $InstallDir"
if (Test-Path $InstallDir) {
    Write-Step "Directory exists. Updating..."
    Push-Location $InstallDir
    try {
        git pull
        Write-Ok "Updated successfully."
    } catch {
        Write-Err "Update failed. Backup and delete the folder to reinstall."
    }
    Pop-Location
} else {
    Write-Step "Cloning repository..."
    try {
        git clone $RepoURL $InstallDir
        if ($LASTEXITCODE -eq 0) { Write-Ok "Cloned successfully." }
        else { throw "Git clone failed." }
    } catch {
        Write-Err "Failed to clone repository. Check internet connection."
        Close-Script
    }
}

# 4. CREATE SHORTCUT
try {
    Write-Step "Creating Desktop shortcut..."
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\WinAuto.lnk")
    $Shortcut.TargetPath = "$InstallDir\WinAuto.bat"
    $Shortcut.WorkingDirectory = "$InstallDir"
    $Shortcut.IconLocation = "shell32.dll,238" # Shield Icon
    $Shortcut.Description = "WinAuto Maintenance Suite"
    $Shortcut.Save()
    Write-Ok "Shortcut created on Desktop."
} catch {
    Write-Err "Failed to create shortcut: $($_.Exception.Message)"
}

# 5. LAUNCH
Write-Host ""
Write-Ok "Installation complete!"
Write-Step "Launching WinAuto..."
Start-Sleep -Seconds 2

# Print padding before handing off control to the batch file or exiting
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""

& "$InstallDir\WinAuto.bat"
