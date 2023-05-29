param grafanaName string 
param grafanaSku string 
param grafanaLocation string 
param azureMonitorWorkspaceResourceId string 

resource grafanaResourceId_grafanaName 'Microsoft.Dashboard/grafana@2022-08-01' = {
  name: grafanaName
  sku: {
    name: grafanaSku
  }
  location: grafanaLocation
  properties: {
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
        }
      ]
    }
  }
}
