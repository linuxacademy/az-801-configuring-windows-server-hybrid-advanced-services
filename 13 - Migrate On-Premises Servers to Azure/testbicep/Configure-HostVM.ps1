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

#Download HyperV VM Creation Scripts
try {
    Write-Log -Entry "Download HyperV VM creation script - Processing..."
    New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/13%20-%20Migrate%20On-Premises%20Servers%20to%20Azure/testbicep/Create-VM.ps1' -OutFile 'C:\temp\Create-VM.ps1'
    Write-Log -Entry "Download HyperV VM creation script - Success"
}
catch {
    Write-Log -Entry "Download HyperV VM creation script - Failure"
    Write-Log $_
}


# Download the 2019 Windows Server Datacenter Eval edition
$VHDLink = 'https://go.microsoft.com/fwlink/p/?linkid=2195334&clcid=0x409&culture=en-us&country=us'
$ParentVHDPath = 'C:\Users\Public\Documents\win-2019-64.vhd'
try {
    Write-Log -Entry "Download VHD - $VHDLink - Processing..."
    Invoke-WebRequest -Uri $VHDLink -OutFile $ParentVHDPath
    Write-Log -Entry "Download VHD - $VHDLink - Success"
}
catch {
    Write-Log -Entry "Download VHD - $VHDLink - Failed"
    Write-Log -Entry "$_"
    Exit
}

# Download the Azure Migrate Appliance VHD
$AzMigAppUrl = 'https://go.microsoft.com/fwlink/?linkid=2191848'
$AzMigAppFilePath = "$($AllUsersDesktop)\azMigApp.zip"
try {
    Write-Log -Entry "Download AzMigrate Appliance VHD - $AzMigAppUrl - Processing..."
    Invoke-WebRequest -uri $AzMigAppUrl -OutFile $AzMigAppFilePath
    Write-Log -Entry "Download AzMigrate Appliance VHD - $AzMigAppUrl - Success"
}
catch {
    Write-Log -Entry "Download AzMigrate Appliance VHD - $AzMigAppUrl - Failed"
    Write-Log -Entry "$_"
    Exit
}

# VM Scheduled Task Creation Loop
try {
    Write-Log -Entry "Creating loop - Processing..."
    $VMs = @('nestedVM1')
    foreach ($VM in $VMs) {
        try {
            Write-Log -Entry "Scheduled task creation for $VM - Processing..."
            # Create scheduled task action
            $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Create-VM.ps1 -UserName $($UserName) -Password $($Password) -VM $($VM) -ParentVHDPath $($ParentVHDPath)"
            Write-Log -Entry "Scheduled task creation for $VM - Success"
        }
        catch {
            Write-Log -Entry "Scheduled task creation for $VM - Failure"
            Write-Log -Entry $_
            Exit
        }
        try {
            # Create scheduled task trigger
            Write-Log -Entry "Schedule task trigger for $VM - Processing..."
            $Trigger = New-ScheduledTaskTrigger -AtStartup
            $Trigger.Delay = 'PT15S'
            Write-Log -Entry "Schedule task trigger for $VM - Success"
        }
        catch {
            Write-Log -Entry "Scheduled task creation for $VM - Failure"
            Write-Log -Entry $_
            Exit
        }
        try {
            Write-Log -Entry "Scheduled task registration for $VM - Processing..."
            Register-ScheduledTask -TaskName "Create-VM $($VM)" -Action $Action -Trigger $Trigger -Description "Create VM" -RunLevel Highest -User "System"
            Write-Log -Entry "Scheduled task registration for $VM - Success"
        }
        catch {
            Write-Log -Entry "Scheduled task registration for $VM - Failure"
            Write-Log -Entry $_
            Exit
        }
    }
    Write-Log -Entry "Creating loop - Success"
}
catch {
    Write-Log -Entry "Creating loop - Failure"
    Write-Log $_
    Exit
}

# Install Hyper-V
try {
    Write-Log -Entry "Install Hyper-V - Processing..."
    Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools
    # Add-WindowsFeature Hyper-V -IncludeManagementTools
    Write-Log -Entry "Install Hyper-V - Success"
}
catch {
    Write-Log -Entry "Install Hyper-V - Failure"
    Write-Log $_
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