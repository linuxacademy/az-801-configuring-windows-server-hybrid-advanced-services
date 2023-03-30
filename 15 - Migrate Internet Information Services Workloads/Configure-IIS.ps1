param(
    $HostVMName
)

# Speed Up Deployment
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Configure Logging
$AllUsersDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
$LogFile = Join-Path -Path $AllUsersDesktop -ChildPath "$($HostVMName)-Hostsetup.log" 

function Write-Log ($Entry, $Path = $LogFile) {
    Add-Content -Path $LogFile -Value "$((Get-Date).ToShortDateString()) $((Get-Date).ToShortTimeString()): $($Entry)" 
}

Write-Log -Entry "Script Run - Started"

# Install web host bundle
try {
    Write-Log -Entry "Install dotnet webhost bundle - Processing..."
    Invoke-WebRequest -Uri 'https://download.visualstudio.microsoft.com/download/pr/c6ad374b-9b66-49ed-a140-588348d0c29a/78084d635f2a4011ccd65dc7fd9e83ce/dotnet-sdk-7.0.202-win-x64.exe' -OutFile 'C:\temp\dotnet-hosting.exe'
    Start-Process -FilePath "C:\temp\dotnet-hosting.exe" -ArgumentList @('/quiet', '/norestart') -Wait -PassThru
    Invoke-WebRequest -Uri 'https://download.visualstudio.microsoft.com/download/pr/d97e0776-b316-4c41-a067-202eb027b968/e9694b0aa94e4b814f980f9ec3d3f400/dotnet-hosting-7.0.4-win.exe' -OutFile 'C:\temp\dotnet-hosting.exe'
    Start-Process -FilePath "C:\temp\dotnet-hosting.exe" -ArgumentList @('/quiet', '/norestart') -Wait -PassThru
    Write-Log -Entry "Install dotnet webhost bundle - Success"
}
catch {
    Write-Log -Entry "Install dotnet webhost bundle - Failed"
    Write-Log -Entry "$_"
    Exit
}

# Create a new ASP.NET MVC Web App
try {
    Write-Log -Entry "Create new ASP.NET Core MVC Web App - Processing..."
    dotnet new webapp -o C:\Temp\TestWebApp
    Write-Log -Entry "Create new ASP.NET Core MVC Web App - Success"
}
catch {
    Write-Log -Entry "Create new ASP.NET Core MVC Web App - Failed"
    Write-Log -Entry "$_"
    Exit
}

# Publish ASP.NET MVC Web App
try {
    Write-Log -Entry "Publish new ASP.Net Core MVC Web App - Processing..."
    dotnet publish C:\Temp\TestWebApp -c Release
    Write-Log -Entry "Publish new ASP.Net Core MVC Web App - Success"
}
catch {
    Write-Log -Entry "Publish new ASP.Net Core MVC Web App - Failed"
    Write-Log -Entry "$_"
    Exit
}

# Compress published solution into deploy.zip
try {
    Write-Log -Entry "Compress publish solution - Processing..."
    cd C:\Temp\TestWebApp\bin\Release\net7.0\publish
    Compress-Archive -Path * -DestinationPath deploy.zip
    Write-Log -Entry "Compress publish solution - Success"
}
catch {
    Write-Log -Entry "Compress publish solution - Failed"
    Write-Log -Entry "$_"
    Exit
}

# Expand deploy.zip into deafult IIS directory
try {
    Write-Log -Entry "Expanding web app into default IIS directory - Processing..."
    Expand-Archive C:\Temp\TestWebApp\bin\Release\net7.0\publish\deploy.zip -DestinationPath C:\inetpub\wwwroot -Force
    Write-Log -Entry "Expanding web app into default IIS directory - Success"
}
catch {
    Write-Log -Entry "Expanding web app into default IIS directory - Failed"
    Write-Log -Entry "$_"
    Exit
}

Write-Log -Entry "Script Run - Completed"