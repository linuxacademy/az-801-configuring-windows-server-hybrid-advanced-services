param(
    [Parameter(Mandatory=$true)]
    $Password,
    [Parameter(Mandatory=$true)]
    $VM,
    $IP = '10.2.1.3',
    $Prefix = '24',
    $DefaultGateway = '10.2.1.1',
    $DNSServers = @('168.63.129.16')
)

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

# Wait for the VM to be ready
try {
    Wait-VMReady -VM $VM
    Write-Log -Entry "Readiness Check $($VM) - Success"
}
catch {
    Write-Log -Entry "Readiness Check $($VM) - Failed"
    Write-Log -Entry $_
    Exit
}

# Wait for the VM to be ready, rename-VM and configure IP Addressing
try {
    Write-Log -Entry "VM Customization Start"
    # Generate Credentials
    $SecurePassword = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ("Administrator", $SecurePassword)

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