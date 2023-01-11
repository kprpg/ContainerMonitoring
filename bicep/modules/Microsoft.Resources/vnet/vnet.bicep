//testing 

param location string
param vnetName string
param vnetAddressPrefix string
param subnetName string
param subnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: subnetAddressPrefix
  }
}
output vnetId string = vnet.id
output subnetId string = subnet.id
