param dataCollectionRuleName string
param workspaceName string
param location string = resourceGroup().location

resource workspaceResource 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource dataCollectionRulesResource 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: dataCollectionRuleName
  location: location
  kind: 'WorkspaceTransforms'
  properties: {
    dataSources: {
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceResource.id
          name: workspaceResource.properties.customerId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Table-SigninLogs'
        ]
        destinations: [
          workspaceResource.properties.customerId
        ]
        transformKql: 'source\n| project-away\n    AlternateSignInName,\n    Identity,\n    LocationDetails,\n    SignInIdentifier,\n    UserPrincipalName,\n    UserDisplayName,\n    UserId,\n    IPAddress,\n    ConditionalAccessPolicies\n\n'
      }
    ]
  }
}
