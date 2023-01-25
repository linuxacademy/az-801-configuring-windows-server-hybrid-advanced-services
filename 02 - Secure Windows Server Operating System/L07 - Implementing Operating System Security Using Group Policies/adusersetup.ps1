start-sleep -s 30 # Giving the DC time to start

# Set username and password for admin of domain
$username = "awesomeadmin"
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force

#Create domain admin
New-ADUser -Name "awesomeadmin" -Description "lab domain admin" -Enabled $true -AccountPassword $pw
Add-ADGroupMember -Identity "Domain Admins" -Members awesomeadmin

#Create "Sales" group and add sales user
New-ADGroup -Name "Sales" -SamAccountName Sales `
    -GroupCategory Security  `
    -GroupScope Global `
    -DisplayName "Sales Team" `
    -Path "CN=Users,DC=corp,DC=awesome,DC=com" `
    -Description "Members of the Sales Team"

New-ADUser -Name "awesomesales" -Description "sales team member" -Enabled $true -AccountPassword $pw
Add-ADGroupMember -Identity "Sales" -Members awesomesales

# Create Domain OU Objects
New-ADOrganizationalUnit `
-Name "Product Engineering" `
-Path "DC=corp,DC=awesome,DC=com"
New-ADOrganizationalUnit `
-Name "Admins" `
-Path "DC=corp,DC=awesome,DC=com"
New-ADOrganizationalUnit `
-Name "Tier 0 Admins" `
-Path "OU=Admins,DC=corp,DC=awesome,DC=com"
New-ADOrganizationalUnit `
-Name "Tier 1 Admins" `
-Path "OU=Admins,DC=corp,DC=awesome,DC=com"
New-ADOrganizationalUnit `
-Name "Tier 2 Admins" `
-Path "OU=Admins,DC=corp,DC=awesome,DC=com"
New-ADOrganizationalUnit `
-Name "Servers" `
-Path "OU=Product Engineering,DC=corp,DC=awesome,DC=com"
New-ADOrganizationalUnit `
-Name "Users" `
-Path "OU=Product Engineering,DC=corp,DC=awesome,DC=com"
New-ADOrganizationalUnit `
-Name "Workstations" `
-Path "OU=Product Engineering,DC=corp,DC=awesome,DC=com"

# Create Admin Groups
New-ADGroup `
-Name "Admins Tier 0" `
-SamAccountName AdminsTier0 `
-GroupCategory Security `
-GroupScope Global `
-DisplayName "Admins Tier 0" `
-Path "OU=Tier 0 Admins,OU=Admins,DC=corp,DC=awesome,DC=com" `
-Description "Tier 0 Admins"
New-ADGroup `
-Name "Admins Tier 1" `
-SamAccountName AdminsTier1 `
-GroupCategory Security `
-GroupScope Global `
-DisplayName "Admins Tier 1" `
-Path "OU=Tier 1 Admins,OU=Admins,DC=corp,DC=awesome,DC=com" `
-Description "Tier 1 Admins"
New-ADGroup `
-Name "Admins Tier 2" `
-SamAccountName AdminsTier2 `
-GroupCategory Security `
-GroupScope Global `
-DisplayName "Admins Tier 2" `
-Path "OU=Tier 2 Admins,OU=Admins,DC=corp,DC=awesome,DC=com" `
-Description "Tier 2 Admins"

# Create Admin Users in Admin Groups
New-ADUser `
-Name "Tier0Admin" `
-OtherAttributes @{'title'="Tier0Admin";'mail'="tier0admind@corp.awesome.com"}
New-ADUser `
-Name "Tier1Admin" `
-OtherAttributes @{'title'="Tier1Admin";'mail'="tier1admind@corp.awesome.com"}
New-ADUser `
-Name "Tier2Admin" `
-OtherAttributes @{'title'="Tier2Admin";'mail'="tier2admind@corp.awesome.com"}

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
$OrganizationalUnit = "OU=Domain Controllers,DC=corp,DC=awesome,DC=com"
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


$OrganizationalUnit = "OU=Servers,OU=Product Engineering,DC=corp,DC=awesome,DC=com"
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

$OrganizationalUnit = "OU=Workstations,OU=Product Engineering,DC=corp,DC=awesome,DC=com"
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
New-GPLink -Name "Tier 0 GPO" -Target "OU=Domain Controllers,DC=corp,DC=awesome,DC=com"
New-GPO -Name "Tier 1 GPO"
New-GPLink -Name "Tier 1 GPO" -Target "OU=Servers,OU=Product Engineering,DC=corp,DC=awesome,DC=com"
New-GPO -Name "Tier 2 GPO"
New-GPLink -Name "Tier 2 GPO" -Target "OU=Workstations,OU=Product Engineering,DC=corp,DC=awesome,DC=com"

# Function to disable IEESC
function Disable-IEESC {

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"

$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0

Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

Stop-Process -Name Explorer

}

# Call function
Disable-IEESC
