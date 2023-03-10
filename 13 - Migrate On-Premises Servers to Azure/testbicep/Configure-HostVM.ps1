 param(
    $UserName,
    $Password,
    $HostVMName = 'vm-az801'
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

Stop-Process -Name Explorer

}

# Diable IEESC
try{
    Write-Log -Entry "Attempting to disable IEESC"
    Disable-IEESC
    Write-Log -Entry "Disabled IEESC successfully"
}
catch {
    Write-Log -Entry "Failed to disable IEESC"
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

#Download Scripts
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

# # Find Windows VHDs
# $urls = @(
#     'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019'
# )

# # Loop through the urls, search for VHD download links and add to totalfound array and display number of downloads
# $totalfound = foreach ($url in $urls) {
#     try {
#         $content = Invoke-WebRequest -Uri $url -ErrorAction Stop
#         $downloadlinks = $content.links | Where-Object { `
#                 $_.'aria-label' -match 'Download' `
#                 -and $_.'aria-label' -match 'VHD'
#         }
#         $count = $DownloadLinks.href.Count
#         $totalcount += $count
#         Write-Log -Entry "Processing $url, Found $count Download(s)..."
#         foreach ($DownloadLink in $DownloadLinks) {
#             [PSCustomObject]@{
#                 Name   = $DownloadLink.'aria-label'.Replace('Download ', '')
#                 Tag    = $DownloadLink.'data-bi-tags'.Split('"')[3].split('-')[0]
#                 Format = $DownloadLink.'data-bi-tags'.Split('-')[1].ToUpper()
#                 Link   = $DownloadLink.href
#             }
#             Write-Log -Entry "Found VHD Image"
#         }
#     }
#     catch {
#         Write-Log -Entry "$url is not accessible"
#         return
#     }
# }


# # Download Information to pass to Create-VM.ps1
# $VHDLink = $totalfound.Link
# $VHDName = $totalfound.Name.Split('-')[0]
# $VHDName = $VHDName.Replace(' ', '-')
# $ParentVHDPath = "C:\Users\Public\Documents\$VHDName.vhd"

# # VM Creation Loop
# try {
#     Write-Log -Entry "Creating loop - Processing..."
#     $VMs = @('nestedVM1')
#     foreach ($VM in $VMs) {
#         try {
#             Write-Log -Entry "Scheduled task creation for $VM - Processing..."
#             # Create scheduled task action
#             $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Create-VM.ps1 -UserName $($UserName) -Password $($Password) -VM $($VM)"
#             Write-Log -Entry "Scheduled task creation for $VM - Success"
#         }
#         catch {
#             Write-Log -Entry "Scheduled task creation for $VM - Failure"
#             Write-Log -Entry $_
#         }
#         try {
#             # Create scheduled task trigger
#             Write-Log -Entry "Schedule task trigger for $VM - Processing..."
#             $Trigger = New-ScheduledTaskTrigger -AtStartup
#             $Trigger.Delay = 'PT15S'
#             Write-Log -Entry "Schedule task trigger for $VM - Success"
#         }
#         catch {
#             Write-Log -Entry "Scheduled task creation for $VM - Failure"
#             Write-Log -Entry $_
#         }
#         try {
#             Write-Log -Entry "Scheduled task registration for $VM - Processing..."
#             Register-ScheduledTask -TaskName "Create-VM $($VM)" -Action $Action -Trigger $Trigger -Description "Create VM" -RunLevel Highest -User "System"
#             Write-Log -Entry "Scheduled task registration for $VM - Success"
#         }
#         catch {
#             Write-Log -Entry "Scheduled task registration for $VM - Failure"
#             Write-Log -Entry $_
#         }
#     }
#     Write-Log -Entry "Creating loop - Success"
# }
# catch {
#     Write-Log -Entry "Creating loop - Failure"
#     Write-Log $_
# }

# Install Hyper-V
try{
    Write-Log -Entry "Install Hyper-V - Processing..."
    Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools
    # Add-WindowsFeature Hyper-V -IncludeManagementTools
    Write-Log -Entry "Install Hyper-V - Success"
}
catch{
    Write-Log -Entry "Install Hyper-V - Failure"
    Write-Log $_
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
}