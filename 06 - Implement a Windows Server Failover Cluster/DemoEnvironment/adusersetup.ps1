start-sleep -s 30 # Giving the DC time to start

$username = "awesomeadmin"
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force

#Create domain admin
New-ADUser -Name "awesomeadmin" -Description "lab domain admin" -Enabled $true -AccountPassword $pw
Add-ADGroupMember -Identity "Domain Admins" -Members awesomeadmin

#Create "Sales" group and add sales user
New-ADGroup -Name "Sales" -SamAccountName Sales `
    -GroupCategory Security  `
    -GroupScope Global `
    -DisplayName "Sales Team" `
    -Path "CN=Users,DC=corp,DC=awesome,DC=com" `
    -Description "Members of the Sales Team"

New-ADUser -Name "awesomesales" -Description "sales team member" -Enabled $true -AccountPassword $pw
Add-ADGroupMember -Identity "Sales" -Members awesomesales

Invoke-WebRequest -Uri "https://webapp-wdac-wizard.azurewebsites.net/packages/WDACWizard_2.1.0.1_x64_8wekyb3d8bbwe.MSIX" -OutFile "$env:USERPROFILE/Downloads/WDACWizard_2.1.0.1_x64_8wekyb3d8bbwe.MSIX"

function Disable-IEESC {

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"

$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0

Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

Stop-Process -Name Explorer

Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green

}

Disable-IEESC

Add-AppxPackage -Path "C:\Users\azureuser\Downloads\WDACWizard_2.1.0.1_x64_8wekyb3d8bbwe.MSIX"
