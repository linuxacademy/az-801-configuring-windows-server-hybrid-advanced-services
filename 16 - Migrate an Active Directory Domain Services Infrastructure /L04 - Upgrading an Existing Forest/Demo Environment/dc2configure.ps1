$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null

mkdir "C:\PS"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/16%20-%20Migrate%20an%20Active%20Directory%20Domain%20Services%20Infrastructure%20/L04%20-%20Upgrading%20an%20Existing%20Forest/Demo%20Environment/adusersetupnewdomain.ps1" -OutFile "C:\PS\adusersetupnewdomain.ps1"

$Trigger= New-ScheduledTaskTrigger -AtStartup
$User= "NT AUTHORITY\SYSTEM"
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\PS\adusersetupnewdomain.ps1"
Register-ScheduledTask -TaskName "create ad account" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force

$Task = Get-ScheduledTask -TaskName 'create ad account'
$Task.Triggers.Repetition.Interval = 'PT1M'
$Task.Triggers.Repetition.Duration = 'PT10M'
$Task | Set-ScheduledTask

Enable-PsRemoting -Force

$User = "corp.awesome.com\awesomeadmin"
$PWord = ConvertTo-SecureString -String "p@55w0rd" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$DomainName = "corp.awesome.com"

Do {

    Try {    
        $Error.Clear() 
        Add-Computer -DomainName $DomainName -Credential $credential -Force
        Start-Sleep -s 5 
    }

    Catch {
        $Error[0].Exception
    }

} While ( $Error.Count -eq 1 )

shutdown.exe /r /t 20
exit
