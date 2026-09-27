# ACLight3 module loader
# Explicitly dot-source the implementation file so unrelated .ps1 files placed
# beside the module are never executed during Import-Module.

$implementationPath = Join-Path -Path $PSScriptRoot -ChildPath 'ACLight2.ps1'

if (-not (Test-Path -LiteralPath $implementationPath -PathType Leaf)) {
    throw "ACLight3 implementation file was not found: $implementationPath"
}

. $implementationPath

Export-ModuleMember -Function @(
    'Get-ObjectAcl',
    'Invoke-ACLScanner',
    'Start-domainACLsAnalysis',
    'Start-ACLsAnalysis'
)
