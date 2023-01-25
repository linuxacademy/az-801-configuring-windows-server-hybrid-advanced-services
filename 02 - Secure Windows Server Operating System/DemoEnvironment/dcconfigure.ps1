$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force

mkdir "C:\PS"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/02%20-%20Secure%20Windows%20Server%20Operating%20System/DemoEnvironment/adusersetup.ps1" -OutFile "C:\PS\adusersetup.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/02%20-%20Secure%20Windows%20Server%20Operating%20System/DemoEnvironment/installWDAC.ps1" -OutFile "C:\PS\installWDAC.ps1" 

# Set trigger at startup
$startUpTrigger= New-ScheduledTaskTrigger -AtStartup
# Set user as system for scheduled task action
$sysUser= "NT AUTHORITY\SYSTEM"
# Set action to be executed at startup as $sysUser
$startUpAction= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\PS\adusersetup.ps1"
Register-ScheduledTask -TaskName "create ad account" -Trigger $startUpTrigger -User $sysUser -Action $startUpAction -RunLevel Highest -Force

$startUpTask = Get-ScheduledTask -TaskName 'create ad account'
$startUpTask.Triggers.Repetition.Interval = 'PT1M'
$startUpTask.Triggers.Repetition.Duration = 'PT10M'
$startUpTask | Set-ScheduledTask

# Set trigger at user login
$userLoginTrigger= New-ScheduledTaskTrigger -AtLogOn
# Set user as local admin user for scheduled task action on login event
$username        = $Args[0]
$localUser= "CORP\$username"
# Set action to be executed at login of $localUser
$userLoginAction= New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\PS\installWDAC.ps1"
Register-ScheduledTask -TaskName 'install wdac' -Trigger $userLoginTrigger -User $localUser -Action $userLoginAction -RunLevel Highest -Force

$userLoginTask = Get-ScheduledTask -TaskName 'install wdac'
$userLoginTask.Triggers.Repetition.Interval = 'PT1M'
$userLoginTask.Triggers.Repetition.Duration = 'PT10M'
$userLoginTask | Set-ScheduledTask

# Install ADDS
Install-ADDSForest -DomainName "corp.awesome.com" -SafeModeAdministratorPassword $pw -DomainNetBIOSName 'CORP' -InstallDns -Force
