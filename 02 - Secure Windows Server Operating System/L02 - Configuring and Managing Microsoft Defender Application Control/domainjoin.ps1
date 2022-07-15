# Join computer corp.awesome.com domain

param
(
      [String]$addsPassword,
      [String]$addsUser,
      [String]$domainName
)

$joinCred = New-Object pscredential -ArgumentList ([pscustomobject]@{
    UserName = "CORP\$addsUser"
    Password = (ConvertTo-SecureString -String $addsPassword -AsPlainText -Force)[0]
})
Add-Computer -Domain $domainName -Credential $joinCred