param workspaceName string

resource workspaceResource 'microsoft.operationalinsights/workspaces@2021-06-01' existing = {
  name: workspaceName
}

resource workspaceNameConainerLogV2 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  parent: workspaceResource
  name: 'ConainerLogV2'
  properties: {
    totalRetentionInDays: 2556
    plan: 'Basic'
    schema: {
      name: 'ConainerLogV2'
    }
    retentionInDays: 365
  }
}

