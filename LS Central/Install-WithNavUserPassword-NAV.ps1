$ErrorActionPreference = 'stop'
Import-Module GoCurrent

$InstanceName = 'LSCentral14'
$UserName = 'admin'
$Password =  ConvertTo-SecureString "MyP@ssw0rd" -AsPlainText -Force

$Arguments = @{
    'bc-server' = @{
        DeveloperServicesEnabled = 'true'
        ClientServicesCredentialType = 'NavUserPassword'
        ServicesCertificateThumbprint = '${internal/self-signed-certificate-private.CertificateThumbprint}'
    }
    'bc-web-client' = @{
        DnsIdentity =  '${internal/self-signed-certificate-public.DnsIdentity}'
    }
    'bc-windows-client' = @{
        DnsIdentity =  '${internal/self-signed-certificate-public.DnsIdentity}'
    }
}

$LsCentralVersion = '14.01'
$BcVersion = (Get-GocUpdates -Id 'ls-central-objects' -Version $LsCentralVersion | Where-Object { $_.Id -eq 'bc-server'}).Version

$Packages = @(
    # Optional, uncomment to include:
    #@{ Id = 'sql-server-express'; VersionQuery = '^-'}
    #@{ Id = 'bc-windows-client'; VersionQuery = ''}
    @{ Id = 'ls-central-demo-database'; VersionQuery = $LsCentralVersion}
    @{ Id = 'bc-server'; VersionQuery = $BcVersion}
    @{ Id = "internal/self-signed-certificate-private"; Version = "" }
    @{ Id = "internal/self-signed-certificate-public"; Version = "" }
    @{ Id = 'ls-central-toolbox-server'; VersionQuery = $LsCentralVersion}
    @{ Id = 'internal/ls-central-dev-license'; VersionQuery = ''}
    @{ Id = 'bc-web-client'; VersionQuery = ''}
)
 
$Packages | Install-GocPackage -InstanceName $InstanceName -UpdateStrategy 'Manual' -Arguments $Arguments -UpdateInstance

# Create NAV user:

$Installed = Get-GocInstalledPackage -Id 'bc-server' -InstanceName $InstanceName

$ServerInstance = $Installed.Info.ServerInstance

Import-Module (Join-Path $Installed.Info.ServerDir 'Microsoft.Dynamics.Nav.Management.dll')

New-NAVServerUser -ServerInstance $ServerInstance -UserName $UserName -Password $Password
$User = Get-NAVServerUser -ServerInstance $ServerInstance | Where-Object { $_.UserName -eq $UserName.ToUpper() }
New-NAVServerUserPermissionSet $ServerInstance -UserName $User.UserName -PermissionSetId SUPER