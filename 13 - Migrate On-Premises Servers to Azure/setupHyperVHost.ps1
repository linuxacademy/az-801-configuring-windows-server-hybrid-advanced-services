$netAdapter = Get-NetAdapter

New-VMSwitch -Name "Nested External Switch"  -NetAdapterName $netAdapter.Name

$vmSwitch = Get-VMSwitch -Name "Nested External Switch"

$vhdDownloadUrl = "https://go.microsoft.com/fwlink/p/?linkid=2195334&clcid=0x409&culture=en-us&country=us"

Invoke-WebRequest -Uri $vhdDownloadUrl -OutFile C:\Temp\winServer2019Eval.vhd

Convert-VHD -Path C:\Temp\winServer2019Eval.vhd -DestinationPath C:\Temp\winServer2019Eval.vhdx

mkdir "C:\VMs"

New-VM -Name NestedTestVM -MemoryStartupBytes 2GB -BootDevice VHD -VHDPath C:\Temp\winServer2019Eval.vhdx -Path C:\VMs -Generation 2 -Switch $vmSwitch.Name

Start-VM -Name NestedTestVM
