
param azureMonitorWorkspaceLocation string 
param clusterName string 
var dceName = 'MSProm-${azureMonitorWorkspaceLocation}-${clusterName}'


resource dce 'Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview' = {
  name: dceName
  location: azureMonitorWorkspaceLocation
  kind: 'Linux'
  properties: {
  }
}
