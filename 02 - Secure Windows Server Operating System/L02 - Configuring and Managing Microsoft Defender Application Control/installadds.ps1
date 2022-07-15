# Install AD DS and configure forest

param
(
      [String]$addsPassword
)

$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null
$pw = ConvertTo-SecureString "$addsPassword" -AsPlainText -Force
#Install-ADDSForest -DomainName "corp.awesome.com" -SafeModeAdministratorPassword $pw -DomainNetBIOSName 'CORP' -InstallDns -Force -NoRebootOnCompletion
Install-ADDSForest `
-SafeModeAdministratorPassword $pw `
-CreateDnsDelegation:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainMode "WinThreshold" `
-DomainName "coolcloudgurus.com" `
-DomainNetbiosName "COOLCLOUDGURUS" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$true `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true


# Create Domain OU Objects
New-ADOrganizationalUnit `
-Name "Product Engineering" `
-Path "DC=coolcloudgurus,DC=COM"
New-ADOrganizationalUnit `
-Name "Admins" `
-Path "DC=coolcloudgurus,DC=COM"
New-ADOrganizationalUnit `
-Name "Tier 0 Admins" `
-Path "OU=Admins,DC=coolcloudgurus,DC=COM"
New-ADOrganizationalUnit `
-Name "Tier 1 Admins" `
-Path "OU=Admins,DC=coolcloudgurus,DC=COM"
New-ADOrganizationalUnit `
-Name "Tier 2 Admins" `
-Path "OU=Admins,DC=coolcloudgurus,DC=COM"
New-ADOrganizationalUnit `
-Name "Servers" `
-Path "OU=Product Engineering,DC=coolcloudgurus,DC=COM"
New-ADOrganizationalUnit `
-Name "Users" `
-Path "OU=Product Engineering,DC=coolcloudgurus,DC=COM"
New-ADOrganizationalUnit `
-Name "Workstations" `
-Path "OU=Product Engineering,DC=coolcloudgurus,DC=COM"

# Create Admin Groups
New-ADGroup `
-Name "Admins Tier 0" `
-SamAccountName AdminsTier0 `
-GroupCategory Security `
-GroupScope Global `
-DisplayName "Admins Tier 0" `
-Path "OU=Tier 0 Admins,OU=Admins,DC=coolcloudgurus,DC=Com" `
-Description "Tier 0 Admins"
New-ADGroup `
-Name "Admins Tier 1" `
-SamAccountName AdminsTier1 `
-GroupCategory Security `
-GroupScope Global `
-DisplayName "Admins Tier 1" `
-Path "OU=Tier 1 Admins,OU=Admins,DC=coolcloudgurus,DC=Com" `
-Description "Tier 1 Admins"
New-ADGroup `
-Name "Admins Tier 2" `
-SamAccountName AdminsTier2 `
-GroupCategory Security `
-GroupScope Global `
-DisplayName "Admins Tier 2" `
-Path "OU=Tier 2 Admins,OU=Admins,DC=coolcloudgurus,DC=Com" `
-Description "Tier 2 Admins"

# Create Admin Users in Admin Groups
New-ADUser `
-Name "Tier0Admin" `
-OtherAttributes @{'title'="Tier0Admin";'mail'="tier0admind@coolcloudgurus.com"}
New-ADUser `
-Name "Tier1Admin" `
-OtherAttributes @{'title'="Tier1Admin";'mail'="tier1admind@coolcloudgurus.com"}
New-ADUser `
-Name "Tier2Admin" `
-OtherAttributes @{'title'="Tier2Admin";'mail'="tier2admind@coolcloudgurus.com"}

Add-ADGroupMember `
-Identity "AdminsTier0" `
-Members Tier0Admin
Add-ADGroupMember `
-Identity "AdminsTier1" `
-Members Tier1Admin
Add-ADGroupMember `
-Identity "AdminsTier2" `
-Members Tier2Admin

# Grant access to groups to OUs
$OrganizationalUnit = "OU=Domain Controllers,DC=coolcloudgurus,DC=COM"
$GroupName = "AdminsTier0"
    
Set-Location AD:
$Group = Get-ADGroup -Identity $GroupName
$GroupSID = [System.Security.Principal.SecurityIdentifier] $Group.SID
$ACL = Get-Acl -Path $OrganizationalUnit
    
$Identity = [System.Security.Principal.IdentityReference] $GroupSID
$ADRight = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
$Type = [System.Security.AccessControl.AccessControlType] "Allow"
$InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "None"
$Rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Identity, $ADRight, $Type,  $InheritanceType)
    
$ACL.AddAccessRule($Rule)
Set-Acl -Path $OrganizationalUnit -AclObject $ACL


$OrganizationalUnit = "OU=Servers,OU=Product Engineering,DC=coolcloudgurus,DC=COM"
$GroupName = "AdminsTier1"
    
Set-Location AD:
$Group = Get-ADGroup -Identity $GroupName
$GroupSID = [System.Security.Principal.SecurityIdentifier] $Group.SID
$ACL = Get-Acl -Path $OrganizationalUnit
    
$Identity = [System.Security.Principal.IdentityReference] $GroupSID
$ADRight = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
$Type = [System.Security.AccessControl.AccessControlType] "Allow"
$InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "None"
$Rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Identity, $ADRight, $Type,  $InheritanceType)
    
$ACL.AddAccessRule($Rule)
Set-Acl -Path $OrganizationalUnit -AclObject $ACL

$OrganizationalUnit = "OU=Workstations,OU=Product Engineering,DC=coolcloudgurus,DC=COM"
$GroupName = "AdminsTier2"
    
Set-Location AD:
$Group = Get-ADGroup -Identity $GroupName
$GroupSID = [System.Security.Principal.SecurityIdentifier] $Group.SID
$ACL = Get-Acl -Path $OrganizationalUnit
    
$Identity = [System.Security.Principal.IdentityReference] $GroupSID
$ADRight = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
$Type = [System.Security.AccessControl.AccessControlType] "Allow"
$InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "None"
$Rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Identity, $ADRight, $Type,  $InheritanceType)
    
$ACL.AddAccessRule($Rule)
Set-Acl -Path $OrganizationalUnit -AclObject $ACL

# Create Tier 0 GPO
New-GPO -Name "Tier 0 GPO"
New-GPLink -Name "Tier 0 GPO" -Target "OU=Domain Controllers,DC=coolcloudgurus,DC=COM"
New-GPO -Name "Tier 1 GPO"
New-GPLink -Name "Tier 1 GPO" -Target "OU=Servers,OU=Product Engineering,DC=coolcloudgurus,DC=COM"
New-GPO -Name "Tier 2 GPO"
New-GPLink -Name "Tier 2 GPO" -Target "OU=Workstations,OU=Product Engineering,DC=coolcloudgurus,DC=COM"
