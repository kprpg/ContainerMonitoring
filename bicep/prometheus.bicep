
param resourceGroupName string
param AzureMonitorWorkspaceName string
param location string

// Azure monitor workspace  deployment
module workspace 'modules/Microsoft.Monitor/azureMonitorWorkspace.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'workspaceDeploy'
  params: {
    PrometheusworkspaceName: AzureMonitorWorkspaceName
    location: location
  }
}

