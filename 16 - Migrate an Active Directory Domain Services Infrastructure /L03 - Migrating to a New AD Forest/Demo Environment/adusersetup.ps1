start-sleep -s 30 # Giving the DC time to start

$username = "awesomeadmin"
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force

#Create domain admin
New-ADUser -Name "awesomeadmin" -Description "lab domain admin" -Enabled $true -AccountPassword $pw
Add-ADGroupMember -Identity "Domain Admins" -Members awesomeadmin
Add-ADGroupMember -Identity "Enterprise Admins" -Members awesomeadmin

#Create "Sales" group and add sales user
New-ADGroup -Name "Sales" -SamAccountName Sales `
    -GroupCategory Security  `
    -GroupScope Global `
    -DisplayName "Sales Team" `
    -Path "CN=Users,DC=corp,DC=awesome,DC=com" `
    -Description "Members of the Sales Team"

New-ADUser -Name "awesomesales" -Description "sales team member" -Enabled $true -AccountPassword $pw
Add-ADGroupMember -Identity "Sales" -Members awesomesales

New-GPO -Name SalesGPO

Add-DnsServerConditionalForwarderZone -Name amazing.local -masterservers 10.0.0.6

Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("127.0.0.1","10.0.0.6")
