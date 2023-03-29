
// The below template deploys a Azure monitor workspace for container monitoring scenarios.

@description('Specify the name of the workspace.')
param workspaceName string

@description('Specify the location for the workspace.')
param location string = resourceGroup().location

resource workspace 'microsoft.monitor/accounts@2021-06-03-preview' = {
  name: workspaceName
  location: location
}
