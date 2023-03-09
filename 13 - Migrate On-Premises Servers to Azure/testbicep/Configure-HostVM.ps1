param(
    $UserName,
    $Password
)

# Speed Up Deployment
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Fix Server UI
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1

#Download Scripts
New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/13%20-%20Migrate%20On-Premises%20Servers%20to%20Azure/testbicep/Create-VM.ps1' -OutFile 'C:\temp\Create-VM.ps1'

# Create VMs
$VMs = @('BRAVM1')
foreach ($VM in $VMs) {
    #Set Scheduled Tasks to create the VM after restart
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Create-VM.ps1 -UserName $($UserName) -Password $($Password) -VM $($VM)"
    # Random dleay so both don't run at exactly the same time
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Trigger.Delay = 'PT15S'
    Register-ScheduledTask -TaskName "Create-VM $($VM)" -Action $Action -Trigger $Trigger -Description "Create VM" -RunLevel Highest -User "System"
}

# Install Hyper-V
Add-WindowsFeature Hyper-V -IncludeManagementTools

#Restart the Server
Restart-Computer -Force