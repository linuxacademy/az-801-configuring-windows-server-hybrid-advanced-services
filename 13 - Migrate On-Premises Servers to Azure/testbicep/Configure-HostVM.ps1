 param(
    $UserName = 'azureuser',
    $Password = 'p@55w0rd',
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

# Call function
Disable-IEESC 

# Fix Server UI
try {
    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
    Write-Log -Entry "Fixed Server UI Successfully" 
}
catch {
    Write-Log -Entry "Fixed Server UI Failed"
    Write-Log $_
}

#Download Scripts
try {
    New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/13%20-%20Migrate%20On-Premises%20Servers%20to%20Azure/testbicep/Create-VM.ps1' -OutFile 'C:\temp\Create-VM.ps1'
    Write-Log -Entry "Download HyperV VM Creation Script Successfully"
}
catch {
    Write-Log -Entry "Download HyperV VM Creation Script Failed"
    Write-Log $_
}

# Find and Download Windows VHDs
$urls = @(
    'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019'
)

#Loop through the urls, search for VHD download links and add to totalfound array and display number of downloads
$ProgressPreference = "SilentlyContinue"
$totalfound = foreach ($url in $urls) {
    try {
        $content = Invoke-WebRequest -Uri $url -ErrorAction Stop
        #Write-Log -Entry "Content=$content"
        $downloadlinks = $content.links | Where-Object { `
                $_.'aria-label' -match 'Download' `
                -and $_.'aria-label' -match 'VHD'
        }
        $count = $DownloadLinks.href.Count
        $totalcount += $count
        Write-Log -Entry "Processing $url, Found $count Download(s)..."
        foreach ($DownloadLink in $DownloadLinks) {
            [PSCustomObject]@{
                Name   = $DownloadLink.'aria-label'.Replace('Download ', '')
                Tag    = $DownloadLink.'data-bi-tags'.Split('"')[3].split('-')[0]
                Format = $DownloadLink.'data-bi-tags'.Split('-')[1].ToUpper()
                Link   = $DownloadLink.href
            }
        }
    }
    catch {
        Write-Log -Entry "$url is not accessible"
        return
    }
}


# Download VHD(s) to $ParentVHDPath
$VHDLink = $totalfound.Link
$VHDName = $totalfound.Name.Split('-')[0]
$VHDName = $VHDName.Replace(' ', '-')
$ParentVHDPath = "C:\Users\Public\Documents\$VHDName.vhd"
try {
    Invoke-WebRequest -Uri "$VHDLink" -OutFile "$ParentVHDPath"
    Write-Log -Entry "Successful Download - $ParentVHDPath"
}
catch {
    Write-Log -Entry "Failed to Download - $ParentVHDPath"
}

# Create VMs
try {
    $VMs = @('nestedVM1')
    foreach ($VM in $VMs) {
        #Set Scheduled Tasks to create the VM after restart
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Create-VM.ps1 -UserName $($UserName) -Password $($Password) -VM $($VM) -ParentVHDPath $($ParentVHDPath)"
        # Random dleay so both don't run at exactly the same time
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        $Trigger.Delay = 'PT15S'
        Register-ScheduledTask -TaskName "Create-VM $($VM)" -Action $Action -Trigger $Trigger -Description "Create VM" -RunLevel Highest -User "System"
        Write-Log -Entry "Succeeded to Create Hyper VM Creation Scheduled Task for $VM"
    }
}
catch {
    Write-Log -Entry "Failed to Create HyperV VM Creation Scheduled Task for $VM"
    Write-Log $_
}

# Install Hyper-V
try{
    Add-WindowsFeature Hyper-V -IncludeManagementTools
    Write-Log -Entry "Succeeded in Install of HyperV"
}
catch{
    Write-Log -Entry "Failed to Install HyperV"
    Write-Log $_
}

#Restart the Server
Restart-Computer -Force 
