param workspaceName string

resource workspaceResource 'microsoft.operationalinsights/workspaces@2021-06-01' existing = {
  name: workspaceName
}

resource workspaceNameContainerLog 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  parent: workspaceResource
  name: 'ContainerLog'
  properties: {
    totalRetentionInDays: 2556
    plan: 'Analytics'
    schema: {
      name: 'ContainerLog'
    }
    retentionInDays: 365
  }
}

