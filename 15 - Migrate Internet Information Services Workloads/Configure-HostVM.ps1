param(
    $UserName,
    $Password,
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

# Function to disable IEESC
function Disable-IEESC {

    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"

    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0

    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

}

# Diable IEESC
try {
    Write-Log -Entry "Disable IEESC - Processing..."
    Disable-IEESC
    Write-Log -Entry "Disabled IEESC - Success"
}
catch {
    Write-Log -Entry "Disable IEESC - Failure"
}

# Fix Server UI
try {
    Write-Log -Entry "Fix server UI - Processing..."
    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
    Write-Log -Entry "Fixed server UI - Success" 
}
catch {
    Write-Log -Entry "Fixed server UI - Failure"
    Write-Log $_
}

# Download IIS Configuration Script
try {
    Write-Log -Entry "Download IIS configuration script - Processing..."
    New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/15%20-%20Migrate%20Internet%20Information%20Services%20Workloads/Configure-IIS.ps1' -OutFile 'C:\temp\Configure-IIS.ps1'
    Write-Log -Entry "Download IIS configuration script - Success"
}
catch {
    Write-Log -Entry "Download IIS configuration script - Failure"
    Write-Log $_
}

# Setup scheduled task action to run IIS configuration script
try {
    Write-Log -Entry "Create IIS configure task action - Processing..."
    # Create scheduled task action
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Configure-IIS.ps1 -HostVMName $($HostVMName)"
    Write-Log -Entry "Create IIS configure task action - Success"
}
catch {
    Write-Log -Entry "Create IIS configure task action - Failure"
    Write-Log -Entry $_
    Exit
}
try {
    # Create scheduled task trigger
    Write-Log -Entry "Create IIS configure task trigger - Processing..."
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Trigger.Delay = 'PT15S'
    Write-Log -Entry "Create IIS configure task trigger - Success"
}
catch {
    Write-Log -Entry "Create IIS configure task trigger - Failure"
    Write-Log -Entry $_
    Exit
}
try {
    Write-Log -Entry "Create IIS configure task registration - Processing..."
    Register-ScheduledTask -TaskName "Configure IIS" -Action $Action -Trigger $Trigger -Description "Configure IIS" -RunLevel Highest -User "System"
    Write-Log -Entry "Create IIS configure task registration - Success"
}
catch {
    Write-Log -Entry "Create IIS configure task registration - Failure"
    Write-Log -Entry $_
    Exit
}

# Install the necessary components on the server
try {
    Write-Log -Entry "Installing IIS - Processing..."
    Install-WindowsFeature -Name 'Web-Server' -IncludeManagementTools -IncludeAllSubFeature -Force
    Write-Log -Entry "Installing IIS - Success"
}
catch {
    Write-Log -Entry "Installing IIS - Failed"
    Write-Log -Entry "$_"
    Exit
}

#Restart the Server
try {
    Write-Log -Entry "Restart server - Processing..."
    Restart-Computer -Force
    Write-Log -Entry "Restart server - Success"   
}
catch {
    Write-Log -Entry "Restart server - Failure"
    Write-Log -Entry $_
    Exit
}