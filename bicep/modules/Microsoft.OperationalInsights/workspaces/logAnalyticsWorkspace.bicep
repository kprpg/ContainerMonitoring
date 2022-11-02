param workspaceName string
param workspaceSkuName string
param location string = resourceGroup().location

resource workspaceResource 'microsoft.operationalinsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: workspaceSkuName
    }
  }
}

resource workspaceName_ContainerLog 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  parent: workspaceResource
  name: 'ContainerLog'
  properties: {
    totalRetentionInDays: 1460
    plan: 'Analytics'
    schema: {
      name: 'ContainerLog'
    }
    retentionInDays: 365
  }
}

output workspaceName string = workspaceResource.name
output workspaceId string = workspaceResource.id
