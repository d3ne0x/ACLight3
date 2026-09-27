#requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$failures = New-Object System.Collections.Generic.List[string]

function Assert-Phase0 {
    param(
        [Parameter(Mandatory=$true)][bool]$Condition,
        [Parameter(Mandatory=$true)][string]$Message
    )

    if ($Condition) {
        Write-Host "[PASS] $Message"
    }
    else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
        $script:failures.Add($Message)
    }
}

Write-Host "ACLight3 Phase 0 validation"
Write-Host "Repository: $repoRoot"
Write-Host ""

# 1. Parse every PowerShell source file without executing AD queries.
$files = Get-ChildItem -Path $repoRoot -Recurse -File |
    Where-Object { $_.Extension -in @('.ps1', '.psm1', '.psd1') }

foreach ($file in $files) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    )
    Assert-Phase0 -Condition ($parseErrors.Count -eq 0) -Message "PowerShell syntax: $($file.FullName.Substring($repoRoot.Length + 1))"
    if ($parseErrors.Count -gt 0) {
        $parseErrors | ForEach-Object { Write-Host ("       {0}" -f $_.Message) -ForegroundColor Red }
    }
}

# 2. Validate the module manifest.
$manifestPath = Join-Path $repoRoot 'ACLight2.psd1'
try {
    $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    Assert-Phase0 -Condition ($manifest.RootModule -eq 'ACLight2.psm1') -Message 'Manifest points to ACLight2.psm1'
    Assert-Phase0 -Condition ($manifest.Version -eq [Version]'3.4.0') -Message 'Manifest version is 3.4.0'
}
catch {
    Assert-Phase0 -Condition $false -Message "Manifest validation: $($_.Exception.Message)"
}

# 3. Import module and confirm only the supported public functions are exported.
try {
    $module = Import-Module -Name $manifestPath -Force -PassThru -ErrorAction Stop
    $expected = @(
        'Get-ObjectAcl',
        'Invoke-ACLScanner',
        'Start-domainACLsAnalysis',
        'Start-ACLsAnalysis'
    ) | Sort-Object
    $actual = @($module.ExportedFunctions.Keys) | Sort-Object
    Assert-Phase0 -Condition (($expected -join '|') -eq ($actual -join '|')) -Message 'Expected public functions are exported'

    # Exercise the private LDAP encoder inside module scope without making LDAP calls.
    $escaped = & $module { ConvertTo-ACLightLdapFilterValue -Value 'svc*(test)\name' }
    Assert-Phase0 -Condition ($escaped -eq 'svc\2a\28test\29\5cname') -Message 'LDAP filter escaping works'

    $wildcard = & $module { ConvertTo-ACLightLdapFilterValue -Value 'admin*' -PreserveWildcard }
    Assert-Phase0 -Condition ($wildcard -eq 'admin*') -Message 'LDAP wildcard preservation works when explicitly requested'
}
catch {
    Assert-Phase0 -Condition $false -Message "Module import/runtime validation: $($_.Exception.Message)"
}
finally {
    Remove-Module ACLight2 -Force -ErrorAction SilentlyContinue
}

# 4. Confirm unsafe legacy launcher/path patterns are gone from active files.
$mainScript = Get-Content -LiteralPath (Join-Path $repoRoot 'ACLight2.ps1') -Raw
$batch = Get-Content -LiteralPath (Join-Path $repoRoot 'Execute-ACLight2.bat') -Raw
Assert-Phase0 -Condition ($batch -notmatch '(?i)ExecutionPolicy\s+Bypass') -Message 'Launcher does not bypass execution policy'
Assert-Phase0 -Condition ($mainScript -notmatch 'C:\\Temp\\scanACLsResults\.csv') -Message 'Legacy C:\Temp output default removed'
Assert-Phase0 -Condition ($mainScript -notmatch '\$exportCsvFile\s*=\s*"C:\\scanACLsResults\.csv"') -Message 'Legacy C:\ output default removed'
Assert-Phase0 -Condition ($mainScript -match 'Initialize-XeloTelemetry') -Message 'XeloTelemetry integration hook is present'
Assert-Phase0 -Condition ($mainScript -match 'Write-XeloInfo') -Message 'XeloTelemetry event/file writer is wired in'

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Host "Phase 0 validation FAILED: $($failures.Count) check(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host 'Phase 0 validation PASSED.' -ForegroundColor Green
exit 0
