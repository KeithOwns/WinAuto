# 🪟 WinAuto: Enterprise-Grade Windows 11 Automation

> **A standardized, modular PowerShell framework for system hardening, maintenance, and configuration management.**

![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=flat-square)
![Language](https://img.shields.io/badge/Language-PowerShell%205.1%2B-5391FE?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## ⚡ Quick Install

Run this command in PowerShell (Admin) to download, install, and launch WinAuto automatically:

```powershell
iex (irm https://raw.githubusercontent.com/KeithOwns/WinAuto/main/setup.ps1)
```

*(This downloads `setup.ps1`, checks dependencies, clones the repo to your Documents folder, and creates a Desktop shortcut.)*

## 📖 Project Overview

**WinAuto** is a comprehensive automation suite designed to demonstrate advanced Windows administration and scripting capabilities. Unlike simple "debloat" scripts, WinAuto is engineered as a **framework** with a focus on reliability, idempotency, and standardized user experience.

It serves as a reference implementation for:
*   **Security Posture Management:** Automating compliance with Microsoft Security Baselines (Defender, Firewall, ASR).
*   **System Maintenance:** Leveraging native Windows APIs (COM, WMI/CIM) for updates and health checks.
*   **Application Deployment:** Automated, silent installation of fundamental runtimes like Visual C++ Redistributables.
*   **Modular Architecture:** A centralized library design that promotes code reuse and maintainability.

---

## 🏗️ Technical Architecture

WinAuto is built on a "Core + Module" architecture to ensure consistency across all 50+ scripts.

### 1. Centralized Logic Engine (`Shared_UI_Functions.ps1`)
To adhere to **DRY (Don't Repeat Yourself)** principles, all scripts inherit their core functionality from a shared kernel.
*   **Unified UI/UX:** A custom ANSI escape sequence engine renders a consistent, high-contrast CLI interface.
*   **Standardized Logging:** Centralized logging with rotation, error trapping, and timestamping.
*   **"The Fuse" Safety Mechanism:** A custom `Invoke-AnimatedPause` function provides a non-blocking, interactive timeout, allowing scripts to run unattended while still offering a "bail-out" window for manual intervention.

### 2. Advanced Automation Techniques
The suite goes beyond basic `Set-ItemProperty` calls, demonstrating proficiency with deeper system interfaces:
*   **Windows Update Agent (COM):** Directly interfaces with the `Microsoft.Update.Session` COM object to trigger scans programmatically, bypassing the UI.
*   **UI Automation:** Uses `.NET UIAutomationTypes` to "drive" the Microsoft Store and Settings apps for tasks that lack public APIs.
*   **Winget Integration:** Wraps the Windows Package Manager for reliable, version-controlled software deployment.

### 3. Self-Validating Code (`CHECK_ScriptQuality`)
Quality assurance is built-in. The suite includes a CI-style validator that audits the codebase for:
*   **Syntax Errors:** Using the `System.Management.Automation.Language.Parser`.
*   **Encoding Compliance:** Enforcing UTF-8 with BOM for reliable character rendering.
*   **Administrator Privileges:** Verifying `#Requires -RunAsAdministrator` directives.

---

## 🛡️ Safety & Reliability

WinAuto is designed for production safety:
*   **Automated Restore Points:** Critical modules invoke `Checkpoint-Computer` before making changes.
*   **Idempotency:** Scripts check current state (Registry/WMI) before applying settings to avoid redundant operations.
*   **Undo Capability:** Configuration scripts support reversion logic to restore default Windows behavior.

---

## 📂 Repository Structure

```text
WinAuto/
├── scripts/
│   ├── Main/              # Entry points (Master Control Suites)
│   ├── Library/           # 50+ Modular, atomic scripts (The "Toolbox")
│   └── Shared/            # Core engine, resources, and UI logic
├── docs/                  # Architecture documentation and standards
└── scriptRULES-WinAuto.ps1 # The "Linter" and style guide enforcer
```

## 🚀 Usage

### Interactive Mode
Run the master bootstrapper to access the full menu system:
```powershell
.\WinAuto.bat
```

### Modular Execution
Each script in `scripts\Library` is standalone and can be executed independently for targeted tasks:
```powershell
# Example: Run only the Security Hardening module
.\scripts\Library\C2_WindowsSecurity_CHECKnSETnSCAN.ps1
```

---

## 👨‍💻 Author

**WinAuto Team**
*Windows 11 Maintenance & Automation Expert*

---
© 2026 AI+IT Support. All Rights Reserved.
