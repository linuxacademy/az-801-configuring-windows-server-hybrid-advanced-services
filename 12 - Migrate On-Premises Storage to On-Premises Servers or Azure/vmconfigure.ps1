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
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/12%20-%20Migrate%20On-Premises%20Storage%20to%20On-Premises%20Servers%20or%20Azure/srcServerSetup.ps1" -OutFile "C:\PS\srcServerSetup.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/12%20-%20Migrate%20On-Premises%20Storage%20to%20On-Premises%20Servers%20or%20Azure/initDataDisk.ps1" -OutFile "C:\PS\initDataDisk.ps1"

# Set trigger at startup
$Trigger= New-ScheduledTaskTrigger -AtStartup
# Set user as local admin user for scheduled task action on login event
$localUser= "CORP\azureuser"
# Set action to be executed at login of $localUser
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "C:\PS\srcServerSetup.ps1"
Register-ScheduledTask -TaskName "install wac" -Trigger $Trigger -User $localUser -Action $Action

$Task = Get-ScheduledTask -TaskName 'install wac'
$Task | Set-ScheduledTask

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
