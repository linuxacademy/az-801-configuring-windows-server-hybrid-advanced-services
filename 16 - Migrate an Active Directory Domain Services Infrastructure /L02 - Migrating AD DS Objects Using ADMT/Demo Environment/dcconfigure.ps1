$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force

mkdir "C:\PS"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/clintbonnett-acg/az-801-testing/main/adusersetup.ps1" -OutFile "C:\PS\adusersetup.ps1"

$Trigger= New-ScheduledTaskTrigger -AtStartup
$User= "NT AUTHORITY\SYSTEM"
$Action= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\PS\adusersetup.ps1"
Register-ScheduledTask -TaskName "create ad account" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force

$Task = Get-ScheduledTask -TaskName 'create ad account'
$Task.Triggers.Repetition.Interval = 'PT1M'
$Task.Triggers.Repetition.Duration = 'PT10M'
$Task | Set-ScheduledTask

Enable-PsRemoting -Force

Install-ADDSForest -DomainName "corp.awesome.com" -SafeModeAdministratorPassword $pw -DomainNetBIOSName 'CORP' -InstallDns -Force
