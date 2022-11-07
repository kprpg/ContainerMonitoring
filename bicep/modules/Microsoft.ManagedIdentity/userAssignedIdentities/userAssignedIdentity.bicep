param location string
param managedIdentityName string
param roleId string


// create an user assigned managed identity
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

// assign role to user assiged managed identity
resource roleassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, roleId, managedIdentityName)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: 'ServicePrincipal'
  }
}

@description('The name of the user assigned identity.')
output name string = userAssignedIdentity.name
