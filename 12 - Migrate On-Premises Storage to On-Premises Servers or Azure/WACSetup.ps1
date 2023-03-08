# Define variables
$url = "https://go.microsoft.com/fwlink/?linkid=2220149&clcid=0x409&culture=en-us&country=us"
$installerPath = "$env:TEMP\WindowsAdminCenterInstaller.msi"
$port = 44320
$arguments = "/i `"$installerPath`" /qn /L*v log.txt SME_PORT=$port SSL_CERTIFICATE_OPTION=generate"

# Download the installer
Invoke-WebRequest -Uri $url -OutFile $installerPath

# Install the Windows Admin Center
Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait

# Open Windows Admin Center in the default browser
Start-Process "https://localhost:$port/"
