# Navigate to where the “AzureADPasswordProtectionProxySetup.exe” was downloaded to

Set-Location <File Location>

#Install Proxy

.\AzureADPasswordProtectionProxySetup.exe /quiet

#Install Azure PowerShell

Install-Module -Name Az -Repository PSGallery -Force

#Register Proxy with AAD

Import-Module AzureADPasswordProtection
Register-AzureADPasswordProtectionProxy -AccountUpn '<Azure Global Administrator Account Name>'

#Register the AD Forest

Register-AzureADPasswordProtectionForest -AccountUpn '<Azure Global Administrator Account Name>'
