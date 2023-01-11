//This bicep module creates a virtual network and a subnet in the virtual network. and outputs the vnet ID.

param location string
param vnetName string
param vnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
