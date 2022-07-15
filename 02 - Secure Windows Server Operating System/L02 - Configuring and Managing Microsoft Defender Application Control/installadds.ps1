# Install AD DS and configure forest

param
(
      [String]$addsPassword
)

$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null
#$pw = ConvertTo-SecureString "$addsPassword" -AsPlainText -Force
$addsPassword = ConvertTo-SecureString $addsPassword -AsPlainText -Force
Install-ADDSForest -DomainName "corp.awesome.com" -SafeModeAdministratorPassword $addsPassword -DomainNetBIOSName 'CORP' -InstallDns -Force -NoRebootOnCompletion
