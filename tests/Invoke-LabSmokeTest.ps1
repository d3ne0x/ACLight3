#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Domain,

    [switch]$Full,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot ('LabResults-{0:yyyyMMdd-HHmmss}' -f (Get-Date))
}

$modulePath = Join-Path $repoRoot 'ACLight2.psd1'
Import-Module $modulePath -Force -ErrorAction Stop

Write-Host "Domain:     $Domain"
Write-Host "Output:     $OutputPath"
Write-Host "Full scan:  $($Full.IsPresent)"
Write-Host ""

$params = @{
    Domain = $Domain
    Full = $Full.IsPresent
    exportCsvFolder = $OutputPath
}

Start-ACLsAnalysis @params

Write-Host ""
Write-Host "Lab smoke test completed. Review:"
Write-Host "  $OutputPath"
Write-Host "  $(Join-Path $repoRoot 'Logs')"
