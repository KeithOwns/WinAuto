# WinAuto Technical Architecture

This document outlines the design philosophy, core components, and technical implementation details of the WinAuto suite. It is intended for technical reviewers and system administrators.

## 1. Design Philosophy

WinAuto is built upon three core pillars:
1.  **Modularity:** Every function is an atomic unit. A script that checks Firewall status should *only* check Firewall status, unless part of a larger orchestration controller.
2.  **Safety:** Automation should never run blindly. Pre-checks, Restore Points, and "Fuse" timeouts are mandatory.
3.  **Consistency:** Every script must look, feel, and log exactly the same way. This is enforced via the Shared Library.

## 2. The Core Engine (`Shared/`)

The heart of WinAuto is the `scripts/Shared/` directory. No script implements its own UI logic; they all inherit from this central engine.

### 2.1. Shared_UI_Functions.ps1
This library standardizes the CLI experience using a custom ANSI rendering engine.

*   **`Write-Header / Write-Footer`**: Enforces the branded "Cyan" headers.
*   **`Write-LeftAligned`**: Handles indentation and text wrapping automatically.
*   **`Write-FlexLine`**: A flexible layout manager that aligns status icons (e.g., "Real-time protection [ON]") across different terminal widths.
*   **`Write-Log`**: A centralized logging function that writes to `$env:WinAutoLogDir`, ensuring audit trails for all actions.

### 2.2. The "Fuse" (`Invoke-AnimatedPause`)
To support both interactive and unattended usage, WinAuto implements a "Fuse" mechanism.
*   **Behavior:** Displays a countdown timer (default 10s) with a visual progress bar.
*   **Logic:** 
    *   If the timer expires: The script proceeds (Unattended mode).
    *   If `Enter` is pressed: The script proceeds immediately.
    *   If any other key is pressed: The script or specific action is skipped.
*   **Code Implementation:** Uses `[System.Diagnostics.Stopwatch]` for precise timing without blocking the thread entirely (unlike `Start-Sleep`).

## 3. Module Architecture

WinAuto scripts are categorized into specific operational layers:

### 3.1. "C-Series" Controllers (Orchestrators)
Located in `scripts/Library`, files starting with `C` (e.g., `C2_WindowsSecurity...`) are orchestrators.
*   They do not contain raw logic.
*   They import specific sub-modules or call atomic functions.
*   **Example:** `C1_WindowsUpdate` calls COM objects to scan, then WMI to check Last Boot time, then Registry keys to configure Active Hours.

### 3.2. Atomic Libraries (`SET_` / `RUN_` / `CHECK_`)
These are the worker units.
*   **`SET_`**: Configuration scripts (Idempotent). Checks state -> Applies if needed -> Verifies.
*   **`RUN_`**: Action scripts (Maintenance). Defrag, Clean Temp, Install App.
*   **`CHECK_`**: Read-only audits. Returns status objects or prints reports.

## 4. Advanced Implementations

### 4.1. COM Object Manipulation
For Windows Update, we bypass the Settings app and speak directly to the OS:
```powershell
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$SearchResult = $UpdateSearcher.Search("IsInstalled=0")
```

### 4.2. UI Automation Framework
Some Windows 11 features (like the Microsoft Store "Get Updates" button) lack a public PowerShell API. WinAuto solves this using `.NET UIAutomation`:
*   Loads `UIAutomationClient` assembly.
*   Finds the process window handle.
*   Traverses the Automation Element Tree to find buttons by Name/AutomationId.
*   Invokes the `InvokePattern` to simulate a physical click.

### 4.3. Self-Validation (`CHECK_ScriptQuality`)
WinAuto ensures its own integrity. The quality checker parses the Abstract Syntax Tree (AST) of every script to ensure:
*   No syntax errors.
*   Correct UTF-8 BOM encoding (critical for the custom Unicode icons).
*   Presence of `#Requires -RunAsAdministrator`.

## 5. Security Standards

*   **Registry Hardening:** All tweaks rely on standard Group Policy (HKLM\Software\Policies) keys where possible, falling back to User Preferences (HKCU) only when necessary.
*   **Least Privilege:** While the suite requires Admin, it checks for this privilege immediately at startup and terminates gracefully if missing.
*   **Logging:** All changes are logged to `C:\Users\admin\GitHub\WinAuto\logs` (configurable), allowing for post-execution auditing.

---
© 2026 AI+IT Support. All Rights Reserved.
