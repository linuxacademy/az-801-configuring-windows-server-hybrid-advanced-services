# Join computer corp.awesome.com domain

$pw = 'p@55w0rd'

$joinCred = New-Object pscredential -ArgumentList ([pscustomobject]@{
    UserName = "CORP\awesomeadmin"
    Password = (ConvertTo-SecureString -String $pw -AsPlainText -Force)[0]
})
Add-Computer -Domain "corp.awesome.com" -Credential $joinCred