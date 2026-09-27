# ACLight3 Phase 0 Testing

This document validates the Phase 0 stabilization work before the branch is merged into `master`.

## 1. Test prerequisites

Use a Windows workstation or server joined to a test/lab Active Directory domain.

Required:

- Windows PowerShell 5.1 or PowerShell 7 on Windows
- Git
- Network connectivity to a domain controller
- A normal domain user is sufficient for the standard read-only LDAP scan
- A writable local clone directory

Do not perform the first live test against production. Validate in a lab/test domain first.

## 2. Get the Phase 0 branch

```powershell
cd C:\Source
git clone https://github.com/d3ne0x/ACLight3.git
cd .\ACLight3
git fetch origin
git switch feature/phase-0-stabilization
git status
```

Expected:

```text
On branch feature/phase-0-stabilization
nothing to commit, working tree clean
```

## 3. Confirm PowerShell version

```powershell
$PSVersionTable
```

Expected: PowerShell 5.1 or later.

## 4. Run the offline validation suite

This test does not query Active Directory.

For Windows PowerShell:

```powershell
powershell.exe -NoLogo -NoProfile -File .\tests\Invoke-Phase0Validation.ps1
```

For PowerShell 7:

```powershell
pwsh.exe -NoLogo -NoProfile -File .\tests\Invoke-Phase0Validation.ps1
```

Expected final line:

```text
Phase 0 validation PASSED.
```

The validation checks:

1. PowerShell parsing for every PS1/PSM1/PSD1 file.
2. Module manifest validity.
3. Correct module version and root module.
4. Expected exported functions.
5. LDAP escaping.
6. LDAP wildcard preservation.
7. Absence of `ExecutionPolicy Bypass` from the launcher.
8. Removal of the legacy hard-coded CSV paths.

If this test fails, do not continue to the live AD test.

## 5. Verify module import manually

```powershell
Import-Module .\ACLight2.psd1 -Force -Verbose
Get-Module ACLight2
Get-Command -Module ACLight2
```

Expected exported functions:

```text
Get-ObjectAcl
Invoke-ACLScanner
Start-domainACLsAnalysis
Start-ACLsAnalysis
```

Remove it afterward if desired:

```powershell
Remove-Module ACLight2
```

## 6. Confirm generated folders

After module import, confirm:

```powershell
Get-ChildItem .\Results
Get-ChildItem .\Logs
```

Both folders should exist. Generated contents are ignored by Git.

## 7. Run the focused lab scan

Replace the example domain with the test domain:

```powershell
.\tests\Invoke-LabSmokeTest.ps1 -Domain "lab.contoso.com"
```

The standard scan is the preferred first live test.

Do not use `-Full` on the first run.

The script creates a timestamped output directory similar to:

```text
LabResults-20260927-123000
```

and log files beneath:

```text
Logs\ACLight3-YYYYMMDD-HHMMSS.log
```

## 8. Review the output

Check for:

```text
Privileged Accounts - Layers Analysis.txt
Privileged Accounts - Final Report.csv
Privileged Accounts - Irregular Accounts.csv
```

Also review:

```powershell
Get-ChildItem .\Logs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-Content (Get-ChildItem .\Logs | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
```

There should be no unhandled LDAP or module errors.

## 9. Test the new launcher

```powershell
.\Start-ACLight3.ps1 -Domain "lab.contoso.com"
```

Then test the batch wrapper:

```powershell
.\Execute-ACLight2.bat -Domain "lab.contoso.com"
```

Both should complete without using `ExecutionPolicy Bypass`.

If your organization blocks unsigned scripts through execution policy/AppLocker/WDAC, ACLight3 should respect that policy rather than circumventing it.

## 10. Compare ACLight3 with the original scanner

For the strongest regression test, run the original `master` branch and the Phase 0 branch against the same lab domain using the same account.

Keep results in separate folders.

Phase 0 may report fewer entries than the original version where the old expression incorrectly treated a DENY ACE as a dangerous effective permission.

Compare:

- AccountName
- AccountGroup
- ActiveDirectoryRights
- ObjectRights
- ObjectDN
- Layer

Any difference should be investigated, particularly entries that disappear from Phase 0.

## 11. Test a Full scan

Only after the standard scan succeeds:

```powershell
.\tests\Invoke-LabSmokeTest.ps1 -Domain "lab.contoso.com" -Full
```

This exercises the broader OU/object scan and can take substantially longer.

## 12. Test a normal non-admin account

Run the same standard smoke test from a normal domain user account.

Expected:

- Scan can perform its normal LDAP reads.
- No domain modifications occur.
- Results are generated.
- Any unreadable cross-domain object is reported without terminating the complete run.

## 13. Git cleanliness check

After all tests:

```powershell
git status
```

Generated `Results`, `Logs`, and `LabResults-*` content should not appear as untracked changes.

## Phase 0 acceptance criteria

Phase 0 is ready to merge when all of the following are true:

- Offline validation reports PASS.
- Module imports without manifest errors.
- Standard lab scan completes.
- Final reports are produced.
- No unexpected unhandled errors appear in the log.
- Batch and PowerShell launchers both work.
- A non-admin domain user can run the normal scan.
- Full scan completes in the lab.
- Differences from the old scanner are explainable, especially DENY ACE removals.
- `git status` remains clean after generated output.


## 14. Optional XeloTelemetry integration test

If you have the XELO telemetry runtime available, load its integration module through the supported launcher:

```powershell
.\Start-ACLight3.ps1 `
  -Domain "lab.contoso.com" `
  -XeloTelemetryModulePath "C:\Source\Xelo-Telemetry\powershell\XeloTelemetry.Integration.psm1"
```

The XeloTelemetry integration module must be able to locate its matching `XeloTelemetry.dll` as documented in the Xelo-Telemetry repository.

Expected telemetry events:

- Event ID 5100: ACLight3 scan started
- Event ID 5101: ACLight3 scan completed
- Event ID 5198: ACL scanner error
- Event ID 5199: ACLight3 runtime/version error

When XeloTelemetry is not loaded or cannot initialize, ACLight3 deliberately falls back to the local `Logs` directory rather than aborting the assessment.
