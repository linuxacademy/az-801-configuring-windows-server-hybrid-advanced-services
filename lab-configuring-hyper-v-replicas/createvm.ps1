#Create Virtual Switch
New-VMSwitch -Name "External VM Switch" -AllowManagementOS $True -NetAdapterName "Ethernet"

# Set VM Name, Switch Name, and Installation Media Path.
$VMName =  "hyperv$env:computername" 
$Switch = (Get-VMSwitch).Name

# Create New Virtual Machine
New-VM -Name $VMName -SwitchName $Switch `
    -MemoryStartupBytes 2GB `
    -Generation 2 `
    -NewVHDPath "C:\Virtual Machines\$VMName\$VMName.vhdx" `
    -NewVHDSizeBytes 20GB `
    -Path "C:\Virtual Machines\$VMName"
