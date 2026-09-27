@{
    RootModule = 'ACLight2.psm1'
    ModuleVersion = '3.4.0'
    GUID = '7e1fe5ea-1a5c-4bb8-a2d5-3d5c02ec5ef4'

    Author = 'Asaf Hecht (@hechtov), CyberArk Labs; ACLight3 stabilization maintained by d3ne0x'
    CompanyName = 'Community'
    Copyright = 'BSD 3-Clause'
    Description = 'Privileged account and Shadow Admin discovery through Active Directory ACL analysis.'

    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    FunctionsToExport = @(
        'Get-ObjectAcl',
        'Invoke-ACLScanner',
        'Start-domainACLsAnalysis',
        'Start-ACLsAnalysis'
    )

    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    FileList = @(
        'ACLight2.psm1',
        'ACLight2.psd1',
        'ACLight2.ps1'
    )

    PrivateData = @{
        PSData = @{
            Tags = @('ActiveDirectory', 'ACL', 'Privilege', 'ShadowAdmin', 'Security')
            LicenseUri = 'https://github.com/d3ne0x/ACLight3/blob/master/LICENSE'
            ProjectUri = 'https://github.com/d3ne0x/ACLight3'
        }
    }
}
