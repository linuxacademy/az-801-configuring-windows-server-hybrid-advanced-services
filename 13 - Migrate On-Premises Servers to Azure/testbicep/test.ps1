# Download WSIM ISO
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2162950" -OutFile "C:\Temp\adksetup.iso"

# Attach ISO
C:\Temp\adksetup.iso

# Sleep
Start-Sleep -Seconds 5

# Run adksetup.exe from attached ISO
# F:\adksetup.exe /quiet /layout c:\temp\ADKoffline
F:\adksetup.exe /quiet /installpath C:\ADK /features OptionId.DeploymentTools
F:\adksetup.exe


# Install ADK
C:\Temp\ADKoffline\adksetup.exe /quiet /installpath c:\ADK /features OptionId.DeploymentTools
