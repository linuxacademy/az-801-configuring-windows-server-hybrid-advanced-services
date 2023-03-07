# Define variables
$shareName = "TestShare"
$directoryPath = "C:\$shareName"
$fullAccessUsers = "awesomeadmin"
$readAccessUsers = "Everyone"
$numFiles = 3  # Change this to the number of files you want to create
$maxFileSize = 10MB  # Change this to the maximum file size you want to create

# Create directory
New-Item -ItemType Directory -Path $directoryPath

# Set up SMB share
New-SmbShare -Name $shareName -Path $directoryPath -FullAccess $fullAccessUsers -ReadAccess $readAccessUsers

# Create random files
$random = New-Object System.Random
for ($i = 1; $i -le $numFiles; $i++) {
    $fileName = "File$i.txt"
    $filePath = Join-Path $directoryPath $fileName
    $fileSize = $random.Next(1, $maxFileSize)
    $fileStream = New-Object IO.FileStream($filePath, [IO.FileMode]::Create)
    $fileStream.SetLength($fileSize)
    $fileStream.Close()
}

# # Define variables
# $url = "https://go.microsoft.com/fwlink/?linkid=2220149&clcid=0x409&culture=en-us&country=us"
# $installerPath = "C:\TEMP\WindowsAdminCenterInstaller.msi"
# $port = 44320
# $arguments = "/i `"$installerPath`" /qn /L*v log.txt SME_PORT=$port SSL_CERTIFICATE_OPTION=generate"

# # Download the installer
# Invoke-WebRequest -Uri $url -OutFile $installerPath

# # Install the Windows Admin Center
# Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait

# # # Add firewall rules to allow remote access
# # New-NetFirewallRule -DisplayName "Windows Admin Center (HTTPS-In)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443
# # New-NetFirewallRule -DisplayName "Windows Admin Center (HTTP-In)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80

# # # Set up Windows Admin Center authentication
# # Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters" -Name "AllowEncryptionOracle" -Value 2
# # Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters" -Name "AllowFreshCredentialsWhenNTLMOnly" -Value 1

# # Open Windows Admin Center in the default browser
# Start-Process "https://localhost:$port/"