param workspaceName string

resource workspaceResource 'microsoft.operationalinsights/workspaces@2021-06-01' existing = {
  name: workspaceName
}

resource workspaceNameContainerLogV2 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: workspaceResource
  name: 'ContainerLogV2'
  properties: {
    totalRetentionInDays: 1826
    plan: 'Basic'
    schema: {
      name: 'ContainerLogV2'
    }
    retentionInDays: 8
  }
}
