# Changelog

## 3.4.0 - Phase 0 stabilization

### Correctness
- Corrected the dangerous-ACE filter so `AccessControlType = Allow` applies to the entire privileged-rights expression.
- Added LDAP filter-value escaping to the main AD object and ACL lookup paths while preserving intentional wildcard searches.

### Packaging
- Repaired the PowerShell module manifest.
- Replaced the invalid module GUID.
- Corrected module/file references to ACLight2 names.
- Explicitly defined the supported public function exports.
- Changed the module loader to dot-source only `ACLight2.ps1`.

### Execution safety
- Removed `-ExecutionPolicy Bypass` from the batch launcher.
- Added `Start-ACLight3.ps1` as the supported launcher.
- Raised the supported baseline to PowerShell 5.1.
- Removed hard-coded `C:\Temp` and `C:\` CSV defaults.
- Ensured output directories are created and resolved before use.

### Diagnostics
- Added timestamped ACLight3 file logging under `Logs`.
- Scanner exceptions now write a diagnostic log entry before presenting the warning.

### Validation
- Added `tests/Invoke-Phase0Validation.ps1` for offline syntax/manifest/module checks.
- Added `tests/Invoke-LabSmokeTest.ps1` for an isolated AD lab scan.
- Added `.gitignore` entries for generated logs and scan results.

### Deliberately deferred
- Splitting the monolithic ACL engine into modules.
- Replacing CSV intermediate state with an in-memory privilege graph.
- Modern AD attack-path rules such as RBCD/AD CS expansion.
- GUI/HTML visualization.
- CyberArk PAM correlation.
