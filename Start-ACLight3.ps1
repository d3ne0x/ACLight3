#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Domain,

    [switch]$Full,

    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath 'Results'),

    [string]$XeloTelemetryModulePath
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'ACLight2.psd1'

try {
    if (-not [string]::IsNullOrWhiteSpace($XeloTelemetryModulePath)) {
        if (-not (Test-Path -LiteralPath $XeloTelemetryModulePath -PathType Leaf)) {
            throw "XeloTelemetry integration module not found: $XeloTelemetryModulePath"
        }
        Import-Module -Name $XeloTelemetryModulePath -Force -ErrorAction Stop
    }

    Import-Module -Name $modulePath -Force -ErrorAction Stop

    $scanParameters = @{
        exportCsvFolder = $OutputPath
        Full = $Full.IsPresent
    }

    if (-not [string]::IsNullOrWhiteSpace($Domain)) {
        $scanParameters.Domain = $Domain
    }

    Start-ACLsAnalysis @scanParameters
    exit 0
}
catch {
    Write-Error ("ACLight3 failed: {0}" -f $_.Exception.Message)
    exit 1
}
