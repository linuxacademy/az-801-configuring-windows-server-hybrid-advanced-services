var location = resourceGroup().location

resource src_vnet_az801 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-hq-az801-01'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'SharedServicesSubnet'
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

resource nsg_az801 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-hq-az801-01'
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

resource public_ip_az801_bastion 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'pip-hq-az801-bastion-01'
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
resource bastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'bastion-hq-az801-01'
  location: location
  sku: {
      name: 'Basic'
  }
  properties: {
      ipConfigurations: [
          {
              name: 'IpConf'
              properties: {
                  publicIPAddress: {
                      id: public_ip_az801_bastion.id
                  }
                  subnet: {
                      id: src_vnet_az801.properties.subnets[1].id
                  }
              }
          }
      ]
  }
}
