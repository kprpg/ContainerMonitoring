param workspaceName string
param workspaceSkuName string
param location string = resourceGroup().location
param solutionTypes array

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

resource workspaceSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for item in solutionTypes: {
  name: '${item}'
  location: location
  properties: {
    workspaceResourceId: workspaceResource.id
  }
  plan: {
    name: '${item}'
    product: 'OMSGallery/${item}'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  dependsOn: [
    workspaceResource
  ]
}]

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
  dependsOn: [
    workspaceSolution
  ]
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
  dependsOn: [
    workspaceSolution
  ]
}

output workspaceName string = workspaceResource.name
output workspaceId string = workspaceResource.id
