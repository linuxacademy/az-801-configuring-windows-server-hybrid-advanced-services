$DomainName = "corp.awesome.com"
$VMName = "dc"
$User = "CORP\awesomeadmin"
$PWord = ConvertTo-SecureString -String "p@55w0rd" -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1

New-NetFirewallRule -DisplayName "AzureILBProbe" -Direction Inbound -LocalPort 59999 -Protocol TCP -Action Allow

Enable-PSRemoting -Force
winrm set winrm/config/service/auth '@{Kerberos="true"}'

mkdir "C:\PS"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/13%20-%20Migrate%20On-Premises%20Servers%20to%20Azure/srcServerSetup.ps1" -OutFile "C:\PS\srcServerSetup.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/13%20-%20Migrate%20On-Premises%20Servers%20to%20Azure/setupHyperVHost.ps1" -OutFile "C:\PS\setupHyperVHost.ps1"

# Set trigger at startup
$startUpTrigger= New-ScheduledTaskTrigger -AtStartup
# Set user as system for scheduled task action
$sysUser= "CORP\azureuser"
# Set action to be executed at startup as $sysUser
$startUpAction= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\PS\setupHyperVHost.ps1"
Register-ScheduledTask -TaskName "setup hyperv vm" -Trigger $startUpTrigger -User $sysUser -Action $startUpAction -RunLevel Highest -Force

$startUpTask = Get-ScheduledTask -TaskName 'setup hyperv vm'
$startUpTask | Set-ScheduledTask

# Function to disable IEESC
function Disable-IEESC {

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"

$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0

Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

Stop-Process -Name Explorer

Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools

}

# Call function
Disable-IEESC

Do {

    Try {    
        $Error.Clear() 
        $join = Add-Computer -DomainName $DomainName -Credential $credential -Force
        Start-Sleep -s 5 
    }

    Catch {
        $Error[0].Exception
    }

} While ( $Error.Count -eq 1 )

shutdown.exe /r /t 20
exit
