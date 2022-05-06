# Install IIS #

Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools

# Create simple HTML website #

echo '<!doctype html><html><body><h1>Hello Cloud Gurus!</h1></body></html>' > C:\inetpub\wwwroot\index.html