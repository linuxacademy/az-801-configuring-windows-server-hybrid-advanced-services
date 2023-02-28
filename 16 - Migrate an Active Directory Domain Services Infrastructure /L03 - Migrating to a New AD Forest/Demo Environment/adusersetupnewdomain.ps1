start-sleep -s 30 # Giving the DC time to start

$username = "awesomeadmin"
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force

#Create domain admin
New-ADUser -Name "awesomeadmin" -Description "lab domain admin" -Enabled $true -AccountPassword $pw
Add-ADGroupMember -Identity "Domain Admins" -Members awesomeadmin

Add-DnsServerConditionalForwarderZone -Name corp.awesome.com -masterservers 10.0.0.4

Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("127.0.0.1","10.0.0.4")
