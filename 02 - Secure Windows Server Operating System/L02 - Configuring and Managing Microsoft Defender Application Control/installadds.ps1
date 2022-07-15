# Install AD DS and configure forest

param
(
    [String]$addsPassword,
    [String]$domainName
)

# Create Net BIOS name for the domain by splitting the domain name by dots and upper case it
$domainNetBIOSName = $domainName.split(".")[0]
# Upper case domain NetBIOS name
$domainNetBIOSName = $domainNetBIOSName.toUpper()
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
-DomainName $domainName `
-DomainNetbiosName $domainNetBIOSName `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
