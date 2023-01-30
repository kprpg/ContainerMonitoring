//This bicep module creates a virtual network and a subnet in the virtual network. and outputs the vnet ID.

param location string
param vnetName string
param vnetAddressPrefix string
param subnetName string
param subnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }

  resource vnetSubnet 'subnets' existing = {
    name: subnetName
  }

}

output vnetId string = vnet.id
output vnetName string = vnet.name
output vnetSubnetId string = vnet::subnet1.id
