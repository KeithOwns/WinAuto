# Changelog

All notable changes to WinAuto are documented here.

---

## [2.2.0] - 2026-03-12

### Added
- **Horizontal UI Compactness:** Removed `.ps1` extensions from the Info page reference map for a cleaner, more horizontally compact layout.
- **Dynamic Manual Mode Banner:** Integrated a prominent `___________________MANUAL MODE_________________` banner (Black on Yellow) when manual mode is engaged.
- **Unified Footer Navigation:** Synchronized footer controls across both Dashboard and Info pages (`KEYS ^ v`, `i` for Info, `Enter` for CSV Export, `Esc` for Return/Exit).

### Improved
- **Color Consistency:** Standardized `DarkCyan` for ACTION/STAGE headers and assigned `Gray` to the STAGE column for improved readability and focus.
- **Selection Highlighting:** Refined the dashboard selection block to use margin-to-margin highlights with consistent 2-space padding and color schemes.
- **Technical Mapping:** Updated the embedded CSV generator to produce cleaner source script names without file extensions.

### Fixed
- **Navigation Flow:** Corrected `Esc` key behavior in the Info page to return to the dashboard instead of exiting the script entirely.
- **UI Slop Removal:** Eliminated legacy divider characters (`=======`) and standardized underscore (`_`) line placement and formatting.
- **App Update Logic:** Removed the 'WinGet App Updates' step from the core suite to focus purely on system configuration and maintenance.

---

## [2.1.0] - 2026-03-03

### Added
- **Integrated Suite Updater:** New `Invoke-WA_UpdateSuite` function that pulls latest changes from GitHub via Git (with stash/pop logic) or direct ZIP download.
- **Enhanced Maintenance Phase:** Maintenance now includes a self-update check and UI automation for Windows Settings and MS Store updates.
- **Dynamic Dashboard UI:** Section headers now dim (DarkGray) when not selected, and highlighted sections feature a clean, margin-aligned colored block.

### Improved
- **UI Alignment:** All dashboard headers and banners now align perfectly with the margin lines for a symmetrical "boxed" appearance.
- **Robustness:** Git repository checks are now silent and include `--ff-only` pulls to prevent interactive hangs.
- **Orchestration:** Added `$manualHeaderColor` logic to dynamically adjust the interface based on the active selection mode (SmartRUN vs Manual).

### Fixed
- **UI Automation Consistency:** Synchronized "Check for Updates" logic across Windows Settings and Microsoft Store.
- **Manifest Synchronization:** Updated the functional outline (Help/Info page) and technical CSV export to exactly match the live dashboard items.

### Changed
- **Header Formatting:** Removed legacy arrow indicators (`=>`, `->`) from all headers in favor of clean margin-to-margin highlighting.

---

## [2.0.0] - 2026-03-01

### Added
- **Interactive Dashboard:** Complete rewrite of the UI using arrow-key navigation and a multi-phase lifecycle.
- **Single-File Delivery:** Consolidated configuration and maintenance logic into `wa.ps1`.
- **SmartRUN Mode:** Added intelligent auditing to skip redundant configuration steps.
- **Atomic Script Embedding:** Embedded core security and maintenance logic directly into the main script.
