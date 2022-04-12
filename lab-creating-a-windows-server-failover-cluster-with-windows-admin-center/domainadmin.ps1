# Create Domain Admin

$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force
New-ADUser -Name "awesomeadmin" -Description "lab domain admin" -Enabled $true -AccountPassword $pw
Add-ADGroupMember -Identity "Domain Admins" -Members awesomeadmin