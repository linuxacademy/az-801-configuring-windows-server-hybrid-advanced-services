# Install the necessary components on the server
Install-WindowsFeature -Name 'Web-Server' -IncludeManagementTools -IncludeAllSubFeature -Force

# Install web host bundle
Invoke-WebRequest -Uri 'https://download.visualstudio.microsoft.com/download/pr/d97e0776-b316-4c41-a067-202eb027b968/e9694b0aa94e4b814f980f9ec3d3f400/dotnet-hosting-7.0.4-win.exe' -OutFile 'C:\temp\dotnet-hosting.exe'
Start-Process -FilePath "C:\temp\dotnet-hosting.exe" -ArgumentList @('/quiet', '/norestart') -Wait -PassThru

# Create a new ASP.NET MVC WEb App
dotnet new webapp -o C:\Temp\TestWebApp

# Publish ASP.NET MVC Web App
dotnet publish C:\Temp\TestWebApp -c Release

# Change directory to published solution
cd C:\Temp\TestWebApp\bin\Release\net7.0\publish

# Compress published solution into deploy.zip
Compress-Archive -Path * -DestinationPath deploy.zip

# Expand deploy.zip into deafult IIS directory
Expand-Archive C:\Temp\TestWebApp\bin\Release\net7.0\publish\deploy.zip -DestinationPath C:\inetpub\wwwroot -Force