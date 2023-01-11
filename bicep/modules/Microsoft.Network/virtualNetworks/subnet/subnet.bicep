//This bicep module creates a virtual network and a subnet in the virtual network. and outputs the vnet ID.

//param subnetAddressPrefix string
//param subnetName string
param  subnets array

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = [ for subnetIDx in subnets: {
  name: subnets[subnetIDx].subnetName
  properties: {
    addressPrefix: subnets[subnetIDx].subnetAddressPrefix
  }
}]

output subnetDeails array = [for (name,subnetIDx ) in subnets: {
  subnetId: subnet[subnetIDx].id
}]

