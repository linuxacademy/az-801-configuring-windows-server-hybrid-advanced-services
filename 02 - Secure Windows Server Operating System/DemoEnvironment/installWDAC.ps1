# Download WDAC installer
Invoke-WebRequest -Uri "https://webapp-wdac-wizard.azurewebsites.net/packages/WDACWizard_2.1.0.1_x64_8wekyb3d8bbwe.MSIX" -OutFile "$env:USERPROFILE\Downloads\WDACWizard_2.1.0.1_x64_8wekyb3d8bbwe.MSIX"
$file = "$env:USERPROFILE\Downloads\WDACWizard_2.1.0.1_x64_8wekyb3d8bbwe.MSIX"
if(Test-Path -Path $file -PathType Leaf) {
   Add-AppxPackage -Path "$file"
}else {
   Write-Output "File Not Found" >> $env:USERPROFILE\installWDAC-Log.txt
}