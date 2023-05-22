param azureMonitorWorkspaceResourceId string
param azureMonitorWorkspaceLocation string
param clusterResourceId string
param clusterLocation string
param grafanaLocation string
param grafanaSku string
param metricLabelsAllowlist string 
param metricAnnotationsAllowList string 
param azureSubscriptionId string 
param resourceGroupName string
param aksName string 
param grafanaName string 

var clusterSubscriptionId = azureSubscriptionId
var clusterResourceGroup = resourceGroupName
var clusterName = aksName
var dceName = 'MSProm-${azureMonitorWorkspaceLocation}-${clusterName}'
var dcrName = 'MSProm-${azureMonitorWorkspaceLocation}-${clusterName}'
var dcraName = 'MSProm-${clusterLocation}-${clusterName}'

resource dce 'Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview' = {
  name: dceName
  location: azureMonitorWorkspaceLocation
  kind: 'Linux'
  properties: {
  }
}

resource dcr 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: dcrName
  location: azureMonitorWorkspaceLocation
  kind: 'Linux'
  properties: {
    dataCollectionEndpointId: dce.id
    dataFlows: [
      {
        destinations: [
          'MonitoringAccount1'
        ]
        streams: [
          'Microsoft-PrometheusMetrics'
        ]
      }
    ]
    dataSources: {
      prometheusForwarder: [
        {
          name: 'PrometheusDataSource'
          streams: [
            'Microsoft-PrometheusMetrics'
          ]
          labelIncludeFilter: {
          }
        }
      ]
    }
    description: 'DCR for Azure Monitor Metrics Profile (Managed Prometheus)'
    destinations: {
      monitoringAccounts: [
        {
          accountResourceId: azureMonitorWorkspaceResourceId
          name: 'MonitoringAccount1'
        }
      ]
    }
  }
}

module azuremonitormetrics_dcra_clusterResourceId 'nested_azuremonitormetrics_dcra_clusterResourceId.bicep' = {
  name: 'azuremonitormetrics-dcra-${uniqueString(clusterResourceId)}'
  scope: resourceGroup(clusterSubscriptionId, clusterResourceGroup)
  params: {
    resourceId_Microsoft_Insights_dataCollectionRules_variables_dcrName: dcr.id
    variables_clusterName: clusterName
    variables_dcraName: dcraName
    clusterLocation: clusterLocation
  }
}

module azuremonitormetrics_profile_clusterResourceId 'nested_azuremonitormetrics_profile_clusterResourceId.bicep'= {
  name: 'azuremonitormetrics-profile--${uniqueString(clusterResourceId)}'
  scope: resourceGroup(clusterSubscriptionId, clusterResourceGroup)
  params: {
    variables_clusterName: clusterName
    clusterLocation: clusterLocation
    clusterResourceId: clusterResourceId
    metricLabelsAllowlist: metricLabelsAllowlist
    metricAnnotationsAllowList: metricAnnotationsAllowList
  }
  dependsOn: [
    azuremonitormetrics_dcra_clusterResourceId
  ]
}

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
