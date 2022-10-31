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

resource workspaceName_Container_SearchJob_Table 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  parent: workspaceResource
  name: 'Container_SearchJob_SRCH'
  properties: {
    totalRetentionInDays: 90
    plan: 'Analytics'
    schema: {
      name: 'Container_SearchJob_SRCH'
      description: 'Search job for demo'
    }
    retentionInDays: 90
  }
}

output workspaceName string = workspaceResource.name
output workspaceId string = workspaceResource.id
