param workspaceName string
param workspaceSkuName string
param retentionPeriod int
param location string = resourceGroup().location

resource workspaceResource 'microsoft.operationalinsights/workspaces@2021-06-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: workspaceSkuName
    }
    retentionInDays: retentionPeriod
  }
}

output workspaceName string = workspaceResource.name
output workspaceId string = workspaceResource.id
