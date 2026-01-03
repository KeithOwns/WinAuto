#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Prints comparison charts for various line styles.
.DESCRIPTION
    Standardized for WinAuto.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "LINE STYLE COMPARISON"

# 1. Connected Lines (Seamless)
$connectedLines = @(
    [PSCustomObject]@{ Hex = "0x2014"; Visual = ([string][char]0x2014 * 20); Name = "Em Dash" }
    [PSCustomObject]@{ Hex = "0x005F"; Visual = ("_" * 20); Name = "Low Line" }
    [PSCustomObject]@{ Hex = "0x268A"; Visual = ([string][char]0x268A * 20); Name = "Monogram Yang" }
    [PSCustomObject]@{ Hex = "0x2500"; Visual = ([string][char]0x2500 * 20); Name = "Box Light" }
    [PSCustomObject]@{ Hex = "0x2501"; Visual = ([string][char]0x2501 * 20); Name = "Box Heavy" }
    [PSCustomObject]@{ Hex = "0x2017"; Visual = ([string][char]0x2017 * 20); Name = "Double Low" }
    [PSCustomObject]@{ Hex = "0x2550"; Visual = ([string][char]0x2550 * 20); Name = "Box Double" }
)

# 2. Broken Lines (Gaps)
$brokenLines = @(
    [PSCustomObject]@{ Hex = "0x002D"; Visual = ("-" * 20); Name = "Hyphen-Minus" }
    [PSCustomObject]@{ Hex = "0x2010"; Visual = ([string][char]0x2010 * 20); Name = "Hyphen" }
    [PSCustomObject]@{ Hex = "0x2013"; Visual = ([string][char]0x2013 * 20); Name = "En Dash" }
    [PSCustomObject]@{ Hex = "0x2212"; Visual = ([string][char]0x2212 * 20); Name = "Math Minus" }
    [PSCustomObject]@{ Hex = "0x00AF"; Visual = ([string][char]0x00AF * 20); Name = "Overline" }
    [PSCustomObject]@{ Hex = "0x2796"; Visual = ([string][char]0x2796 * 10); Name = "Heavy Minus" }
)

Write-LeftAligned "$Bold$FGCyan Connected Lines (Seamless)$Reset"
$connectedLines | Format-Table -AutoSize

Write-Host ""
Write-LeftAligned "$Bold$FGYellow Broken Lines (Gaps)$Reset"
$brokenLines | Format-Table -AutoSize

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""






