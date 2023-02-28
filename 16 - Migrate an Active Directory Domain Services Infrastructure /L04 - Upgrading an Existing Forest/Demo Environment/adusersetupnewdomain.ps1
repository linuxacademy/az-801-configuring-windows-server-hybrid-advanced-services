start-sleep -s 30 # Giving the DC time to start

$User = "corp.awesome.com\awesomeadmin"
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $pw

Unregister-ScheduledTask -TaskName "create ad account" -Confirm:$false

Install-ADDSDomainController -InstallDns -DomainName "corp.awesome.com" -SafeModeAdministratorPassword $pw -Credential $Credential -Force