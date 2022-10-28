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
    retentionInDays: 90
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

resource workspaceName_ContainerLogV2 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  parent: workspaceResource
  name: 'ContainerLogV2'
  properties: {
    totalRetentionInDays: 1460
    plan: 'Basic'
    schema: {
      name: 'ContainerLogV2'
    }
    retentionInDays: 8
  }
}

output workspaceName string = workspaceResource.name
output workspaceId string = workspaceResource.id
