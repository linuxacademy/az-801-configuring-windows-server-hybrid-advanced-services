param(
    $UserName,
    $Password,
    $ParentVHDPath,
    $VM,
    $IP = '10.2.1.2',
    $Prefix = '24',
    $DefaultGateway = '10.2.1.1',
    $DNSServers = @('168.63.129.16')
)
# Set the Error Action Preference
$ErrorActionPreference = 'Stop'

# Configure Logging
$AllUsersDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
$LogFile = Join-Path -Path $AllUsersDesktop -ChildPath "$($VM)-Labsetup.log" 

function Write-Log ($Entry, $Path = $LogFile) {
    Add-Content -Path $LogFile -Value "$((Get-Date).ToShortDateString()) $((Get-Date).ToShortTimeString()): $($Entry)" 
} 
function Wait-VMReady ($VM) {
    while ((Get-VM $VM | Select-Object -ExpandProperty Heartbeat) -notlike "Ok*") {
        Start-Sleep -Seconds 1
    }
}
function Wait-VMPowerShellReady ($VM, $Credential) {
    while (-not (Invoke-Command -ScriptBlock { Get-ComputerInfo } -VMName $VM -Credential $Credential -ErrorAction SilentlyContinue)) {
        Start-Sleep -Seconds 1
    }
}

#Start a stopwatch to measure the deployment time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#Detect if Hyper-V is installed
if ((Get-WindowsFeature -Name 'Hyper-V').InstallState -ne 'Installed') {
    Write-Log -Entry "Hyper-V Role and/or required PowerShell module is not installed, please install before running this script..."
    Exit
}
else {
    Write-Log -Entry "Hyper-V Role is installed, continuing..."
    Write-Log -Entry $_
}

# Import Hyper-V Module
try {
    Import-Module Hyper-V
    Write-Log -Entry "Imported Hyper-V Module Successfully"
}
catch {
    Write-Log -Entry "Failed to Import Hyper-V Module"
    Write-Log -Entry $_
    Exit
}

# Wait for Hyper-V
while (-not(Get-VMHost -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 5
}

# Create NAT Virtual Switch
Write-Log -Entry "VM Creation Start"
try {
    if (-not(Get-VMSwitch -Name "InternalvSwitch" -ErrorAction SilentlyContinue)) {
        Write-Log -Entry "Create Virtual Switch Start"
        New-VMSwitch -Name 'InternalvSwitch' -SwitchType 'Internal'
        New-NetNat -Name LocalNAT -InternalIPInterfaceAddressPrefix '10.2.1.0/24'
        Get-NetAdapter "vEthernet (InternalvSwitch)" | New-NetIPAddress -IPAddress 10.2.1.1 -AddressFamily IPv4 -PrefixLength 24
        Write-Log -Entry "Create Virtual Switch Success"
    }
}
catch {
    Write-Log -Entry "Create Virtual Switch Failed. Please contact Support."
    Write-Log $_
    Exit
}

# Create VHD
try {
    Write-Log -Entry "Create VHD Start"
    New-VHD -ParentPath "$ParentVHDPath" -Path "C:\Temp\$($VM).vhd" -Differencing
    Write-Log -Entry "Create VHD Success"
}
catch {
    Write-Log -Entry "Create VHD Failed. Please contact support."
    Write-Log -Entry $_
    Exit
}

# Download Answer File 
try {
    Write-Log -Entry "Download Answer File Start"
    New-Item -Path "C:\Temp\$($VM)" -ItemType Directory -ErrorAction SilentlyContinue
    $AnswerFilePath = "C:\Temp\$($VM)\unattend.xml"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/13%20-%20Migrate%20On-Premises%20Servers%20to%20Azure/testbicep/unattend.xml" -OutFile $AnswerFilePath
    Write-Log -Entry "Download Answer File Success"
}
catch {
    Write-Log -Entry "Download Answer File Failed. Please contact Support."
    Write-Log -Entry $_
    Exit
}

# Update Answer File
try {
    Write-Log -Entry "Update Answer File Start"
    # Inject ComputerName into Answer File
    (Get-Content $AnswerFilePath) -Replace '%COMPUTERNAME%', "$($VM)" | Set-Content $AnswerFilePath

    # Inject Password into Answer File
    (Get-Content $AnswerFilePath) -Replace '%LABPASSWORD%', "$($Password)" | Set-Content $AnswerFilePath
    Write-Log -Entry "Update Answer File Success"
}
catch {
    Write-Log -Entry "Update Answer File Failed. Please contact Support."
    Write-Log -Entry $_
    Exit
}

# Inject Answer File into VHD
try {
    Write-Log -Entry "Inject Answer File into VHD Start"
    $Volume = Mount-VHD -Path "C:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
    New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
    Copy-Item $AnswerFilePath "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"
    Write-Log -Entry "Inject Answer File into VHD Success"
}
catch {
    Write-Log -Entry "Inject Answer File into VHD Failed. Please contact Support."
    Write-Log -Entry $_
    Exit
}

# Dismount the VHD
try {
    Write-Log -Entry "Dismount VHD Start"
    Dismount-VHD -Path "C:\Temp\$($VM).vhd"
    Write-Log -Entry "Dismount VHD Success"
}
catch {
    Write-Log -Entry "Dismount VHD Failed. Please contact Support."
    Write-Log -Entry $_
    Exit
}

# Create and Start VM
try {
    Write-Log -Entry "Create and Start VM Start"
    # Create Virtual Machine
    New-VM -Name "$($VM)" -Generation 1 -MemoryStartupBytes 2GB -VHDPath "C:\Temp\$($VM).vhd" -SwitchName 'InternalvSwitch'
    Set-VMProcessor "$($VM)" -Count 2
    Set-VMProcessor "$($VM)" -ExposeVirtualizationExtensions $true

    # Ensure Enhanced Session Mode is enabled on the host and VM
    Set-VMhost -EnableEnhancedSessionMode $true
    Set-VM -VMName "$($VM)" -EnhancedSessionTransportType HvSocket

    # Start the VM
    Start-VM -VMName "$($VM)" 
    Write-Log -Entry "Create and Start VM Success"
}
catch {
    Write-Log -Entry "Create and Start VM Failed. Please contact Support."
    Write-Log -Entry $_
    Exit
}

# Wait for the VM to be ready, rename-VM and configure IP Addressing
try {
    Write-Log -Entry "VM Customization Start"
    # Generate Credentials
    $SecurePassword = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ("Administrator", $SecurePassword)

    # Wait for the VM to be ready
    try {
        Wait-VMReady -VM $VM
        Write-Log -Entry "$($VM) is ready"
    }
    catch {
        Write-Log -Entry "$($VM) is not ready"
        Write-Log -Entry $_
        Exit
    }
    # Wait-VMReady -VM $VM
    # Write-Log -Entry "$($VM) is ready"

    try {
        # Wait for Unattend to run
        Wait-VMPowerShellReady -VM $VM -Credential $Credential
        Write-Log -Entry "$($VM) PowerShell is ready"
    }
    catch {
        Write-Log -Entry "$($VM) PowerShell is not ready"
        Write-Log -Entry $_
        Exit
    }

    # Configure IP addresssing
    try {
        Invoke-Command -ScriptBlock { New-NetIPAddress -IPAddress $using:IP -PrefixLength $using:Prefix -InterfaceAlias (Get-NetIPInterface -InterfaceAlias "*Ethernet*" -AddressFamily IPv4 | Select-Object -Expand InterfaceAlias) -DefaultGateway $using:DefaultGateway | Out-Null } -VMName $VM -Credential $Credential
        Write-Log -Entry "Update $($VM) IP - Success"
    }
    catch {
        Write-Log -Entry "Update $($VM) IP - Failed"
        Write-Log -Entry $_
        Exit
    }
    # Configure DNS
    try {
        Invoke-Command -ScriptBlock { Set-DnsClientServerAddress -InterfaceAlias (Get-NetIPInterface -InterfaceAlias "*Ethernet*" -AddressFamily IPv4 | Select-Object -Expand InterfaceAlias) -ServerAddresses $using:DNSServers | Out-Null } -VMName $VM -Credential $Credential
        Write-Log -Entry "Update $($VM) DNS - Success"
    }
    catch {
        Write-Log -Entry "Update $($VM) DNS - Failed"
        Write-Log -Entry $_
        Exit
    }
    
    # Rename VM
    try {
        Invoke-Command -ScriptBlock { Rename-Computer -NewName $using:VM -Restart:$false } -VMName $VM -Credential $Credential
        Write-Log -Entry "Update $($VM) Name - Success"
    }
    catch {
        Write-Log -Entry "Update $($VM) Name - Failed"
        Write-Log -Entry $_
        Exit
    }

    # Restart VM
    try {
        Restart-VM -Name "$($VM)" -Force
        Write-Log -Entry "Restart $($VM) - Success"
    }
    catch {
        Write-Log -Entry "Restart $($VM) - Failed"
        Write-Log -Entry $_
        Exit
    }
    
    Write-Log -Entry "VM Customization Success"
}
catch {
    Write-Log -Entry "VM Customization Failed. Please contact Support."
    Write-Log -Entry $_
    Exit
}

try {
    Wait-VMReady -VM $VM
    Write-Log -Entry "Readiness Check $($VM) - Success"
}
catch {
    Write-Log -Entry "Readiness Check $($VM) - Failed"
    Write-Log -Entry $_
    Exit
}

# Command to run in guest vm
$command = {
    # Define variables
    $shareName = "TestShare"
    $directoryPath = "C:\$shareName"
    $fullAccessUsers = "Everyone"
    $numFiles = 3  # Change this to the number of files you want to create
    $maxFileSize = 1MB  # Change this to the maximum file size you want to create

    # Share parameters
    $Parameters = @{
        Name       = $shareName
        Path       = $directoryPath
        FullAccess = $fullAccessUsers
    }

    # Create directory
    New-Item -ItemType Directory -Path $directoryPath

    # Set up SMB share
    New-SmbShare @Parameters

    # Create random files
    $random = New-Object System.Random
    for ($i = 1; $i -le $numFiles; $i++) {
        $fileName = "File$i.txt"
        $filePath = Join-Path $directoryPath $fileName
        $fileSize = $random.Next(1, $maxFileSize)
        $fileStream = New-Object IO.FileStream($filePath, [IO.FileMode]::Create)
        $fileStream.SetLength($fileSize)
        $fileStream.Close()
    }
}

# Setup File Share on Guest
try {
    Write-Log -Entry "Configure share on Hyper-V Guest VM - Attempting..."
    Invoke-Command -ScriptBlock $command -VMName $VM -Credential $Credential
    Write-Log -Entry "Configure share on Hyper-V Guest VM - Success"
}
catch {
    Write-Log -Entry "Configure share on Hyper-V Guest VM - Failed"
    Exit
}

# Resize guest VM display settings
try {
    Invoke-Command -ScriptBlock { Set-DisplayResolution -Width 1024 -Height 768 -Force } -VMName $VM -Credential $Credential
    Write-Log -Entry "Resize display settings on $($VM) - Success"
}
catch {
    Write-Log -Entry "Resize display settings on $($VM) - Failed"
    Write-Log $_
    Exit
}

# Disable IEESC on guest vm
$command = {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"

    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0

    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
}
try {
    Invoke-Command -ScriptBlock { $command } -VMName $VM -Credential $Credential
    Write-Log -Entry "Disable IEESC on $VM - Success"
}
catch {
    Write-Log -Entry "Disable IEESC on $VM - Failed"
}

#The end, stop stopwatch and display the time that it took to deploy
$stopwatch.Stop()
$hours = $stopwatch.Elapsed.Hours
$minutes = $stopwatch.Elapsed.Minutes
$seconds = $stopwatch.Elapsed.Seconds

Write-Log -Entry "Deployment Completed Successfully - Deployment Time in HH:MM:SS format - $($hours):$($minutes):$($seconds)"