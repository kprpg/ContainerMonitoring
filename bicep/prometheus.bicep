@description('Specify the name of the resource group.')
param resourceGroup string

@description('Specify the name of the workspace.')
param workspaceName string

@description('Specify the location for the workspace.')
param location string


// Azure monitor workspace  deployment

module workspace 'modules/Microsoft.Monitor/azureMonitorWorkspace.bicep' = {
  scope: az.resourceGroup(resourceGroup)
  name: 'workspaceDeploy'
  params: {
    workspaceName: workspaceName
    location: location
  }
}
