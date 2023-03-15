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

Stop-Process -Name Explorer

}

# # Check script for psboundparams
# function Get-ScriptParameters {
#     [CmdletBinding()]
#     param()

#     Write-Log -Entry "Get-ScriptParameters - Processing..."
#     Write-Log -Entry "PSBoundParameters.Count: $($PSBoundParameters.Count)"

#     if ($PSBoundParameters.Count -gt 0) {
#         foreach ($key in $PSBoundParameters.Keys) {
#             Write-Log -Entry "Parameter name: $key"
#             Write-Log -Entry "Parameter value: $($PSBoundParameters[$key])"
#             Write-Log -Entry "Object type: $([Type]::GetType($PSBoundParameters[$key]))"
#         }
#     }
#     else {
#         Write-Log -Entry "No parameters were passed to the script"
#     }
# }

# try{
#     $ScriptParameters = $($PSBoundParameters)
#     Write-Log "Get PSBoundParameters - Processing..."
#     Write-Log -Entry "Bound Paramertes - $ScriptParameters"
#     if ($ScriptParameters.Count -gt 0) {
#         foreach ($key in $ScriptParameters.Keys) {
#             Write-Log -Entry "Getting Parameter..."
#             Write-Log -Entry "Parameter name: $key"
#             Write-Log -Entry "Parameter value: $($ScriptParameter[$key])"
#             Write-Log -Entry "Object Type: $([Type]::GetType($ScriptParameters[$key]))"
#         }
#     }
#     Write-Log -Entry "Parmeters counted - $($PSBoundParameters.Count)"
# }
# catch{
#     Write-Log -Entry "Get PSBoundParemeters - Failed"
#     Write-Log -Entry $_
# }

# # Check script for parameters, param value, and param object type
# try{
#     Write-Log -Entry "Parameter check - Processing..."
#     Get-ScriptParameters
#     Write-Log -Entry "Parameter check - Success"
# }
# catch{
#     Write-Log -Entry "Parameter check - Failure"
#     Write-Log -Entry $_
# }

# Diable IEESC
try{
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
#         $content = Invoke-WebRequest -Uri $url
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

$VHDLink = 'https://go.microsoft.com/fwlink/p/?linkid=2195334&clcid=0x409&culture=en-us&country=us'
$ParentVHDPath = 'C:\Users\Public\Documents\win-2019-64.vhd'

try{
    Write-Log -Entry "Download VHD - $VHDLink - Processing..."
    Invoke-WebRequest -Uri $VHDLink -OutFile $ParentVHDPath
    Write-Log -Entry "Download VHD - $VHDLink - Success"
}
catch {
    Write-Log -Entry "Download VHD - $VHDLink - Failed"
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
try{
    Write-Log -Entry "Install Hyper-V - Processing..."
    Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools
    # Add-WindowsFeature Hyper-V -IncludeManagementTools
    Write-Log -Entry "Install Hyper-V - Success"
}
catch{
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