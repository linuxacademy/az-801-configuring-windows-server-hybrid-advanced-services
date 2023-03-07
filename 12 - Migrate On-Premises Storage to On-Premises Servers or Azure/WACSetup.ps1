# Define variables
$url = "https://go.microsoft.com/fwlink/?linkid=2220149&clcid=0x409&culture=en-us&country=us"
$installerPath = "$env:TEMP\WindowsAdminCenterInstaller.msi"
$port = 44320
$arguments = "/i `"$installerPath`" /qn /L*v log.txt SME_PORT=$port SSL_CERTIFICATE_OPTION=generate"

# Download the installer
Invoke-WebRequest -Uri $url -OutFile $installerPath

# Install the Windows Admin Center
Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait

# # Add firewall rules to allow remote access
# New-NetFirewallRule -DisplayName "Windows Admin Center (HTTPS-In)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443
# New-NetFirewallRule -DisplayName "Windows Admin Center (HTTP-In)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80

# # Set up Windows Admin Center authentication
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters" -Name "AllowEncryptionOracle" -Value 2
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters" -Name "AllowFreshCredentialsWhenNTLMOnly" -Value 1

# Open Windows Admin Center in the default browser
Start-Process "https://localhost:$port/"
