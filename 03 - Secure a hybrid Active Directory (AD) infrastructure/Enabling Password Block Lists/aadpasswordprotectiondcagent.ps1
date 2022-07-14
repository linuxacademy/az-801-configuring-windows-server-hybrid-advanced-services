#Install DC Agent on Domain Controller

#Navigate to where the “AzureADPasswordProtectionDCAgentSetup.msi” was downloaded to

Set-Location <File Location>

#Install DC Agent

msiexec.exe /i AzureADPasswordProtectionDCAgentSetup.msi /quiet /qn /norestart