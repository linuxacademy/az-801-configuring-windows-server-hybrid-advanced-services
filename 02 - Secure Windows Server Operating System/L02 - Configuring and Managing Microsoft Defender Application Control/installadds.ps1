# Install AD DS and configure forest

param
(
    [String]$adminUser,
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

# Download powershell script from github to the downloads folder
# $webClient = New-Object System.Net.WebClient
# $webClient.DownloadFile('https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/02%20-%20Secure%20Windows%20Server%20Operating%20System/create-domainObjects.ps1', 'C:\Users\$adminUser\Downloads\create-domainObjects.ps1')
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/02%20-%20Secure%20Windows%20Server%20Operating%20System/create-domainObjects.ps1' -OutFile 'C:\Users\cloudchase\Downloads\createDomainObjects.ps1'

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
