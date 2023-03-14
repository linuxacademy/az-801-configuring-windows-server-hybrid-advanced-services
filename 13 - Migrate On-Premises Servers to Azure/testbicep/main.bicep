// param location string = resourceGroup().location
param vmUserName string
@secure()
param vmPassword string

var location = resourceGroup().location

// var customImageDefinitionName = 'Win2022_Eval_VHD'
// var customImageResourceId = resourceId('07089ab1-6f34-49b2-9cad-f1a654494a69', 'LACustomImagesRG', 'Microsoft.Compute/galleries/images/versions', 'LAImagesGallery', customImageDefinitionName, 'latest')

resource vnet_az801 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet-az801'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'server-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg_az801.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/26'
        }
      }
    ]
  }
}

resource nsg_az801 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-az801'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAnyRDPInbound'
        properties: {
          description: 'Allow inbound RDP traffic from all VMs to Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource pip_az801 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pip-az801'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic_az801 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-az801'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'nic-az801-IPConfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.5'
          publicIPAddress: {
            id: pip_az801.id
          }
          subnet: {
            id: vnet_az801.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource vm_az801 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-az801'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'standard_d2s_v3'
    }
    osProfile: {
      computerName: 'vm-az801'
      adminUsername: vmUserName
      adminPassword: vmPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'vm-az801-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic_az801.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource vm_az801_CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vm_az801
  name: 'vm-az801-CSE'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/linuxacademy/az-801-configuring-windows-server-hybrid-advanced-services/main/13%20-%20Migrate%20On-Premises%20Servers%20to%20Azure/testbicep/Configure-HostVM.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Configure-HostVM.ps1 -UserName "${vmUserName}" -Password "${vmPassword}" -HostVMName "${vm_az801.name}"'
    }
  }
}

resource public_ip_az801_bastion 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'pip-az801-bastion'
  location: location
  sku: {
      name: 'Standard'
  }
  properties: {
      publicIPAddressVersion: 'IPv4'
      publicIPAllocationMethod: 'Static'
  }
}

// Create the Azure Bastion resource
resource bastion 'Microsoft.Network/bastionHosts@2020-11-01' = {
  name: 'b59-bastion'
  location: location
  sku: {
      name: 'Basic'
  }
  properties: {
      ipConfigurations: [
          {
              name: 'IpConf'
              properties: {
                  privateIPAllocationMethod: 'Dynamic'
                  publicIPAddress: {
                      id: public_ip_az801_bastion.id
                  }
                  subnet: {
                      id: vnet_az801.properties.subnets[1].id
                  }
              }
          }
      ]
  }
}
