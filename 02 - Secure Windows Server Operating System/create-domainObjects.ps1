# Create Domain OU Objects
New-ADOrganizationalUnit `
-Name "Product Engineering" `
-Path "DC=coolcloudgurus,DC=COM"
New-ADOrganizationalUnit `
-Name "Admins" `
-Path "DC=coolcloudgurus,DC=COM"
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
-Path "CN=Users,DC=coolcloudgurus,DC=Com" `
-Description "Tier 0 Admins"
New-ADGroup `
-Name "Admins Tier 1" `
-SamAccountName AdminsTier1 `
-GroupCategory Security `
-GroupScope Global `
-DisplayName "Admins Tier 1" `
-Path "CN=Users,DC=coolcloudgurus,DC=Com" `
-Description "Tier 1 Admins"
New-ADGroup `
-Name "Admins Tier 2" `
-SamAccountName AdminsTier2 `
-GroupCategory Security `
-GroupScope Global `
-DisplayName "Admins Tier 2" `
-Path "CN=Users,DC=coolcloudgurus,DC=Com" `
-Description "Tier 2 Admins"

# Create Admin Users in Admin Groups
New-ADUser `
-Name "Tier0Admin" `
-OtherAttributes @{'title'="Tier0Admin";'mail'="tier0admind@coolcloudgurus.com"}
Add-ADGroupMember `
-Identity "AdminTier0" `
-Members Tier0Admin
