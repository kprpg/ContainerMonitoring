param location string
param clusterName string
param primaryAgentPoolProfile array
param workspaceResourceId string = ''
param omsAgentEnabled bool = true
param dockerBridgeCidr string
param serviceCidr string
param networkPolicy string
param networkPlugin string
param kubernetesVersion string
param variables_clusterName string
param clusterLocation string
param clusterResourceId string
param metricLabelsAllowlist string
param metricAnnotationsAllowList string
param Prometheusstage string 
param resourceId_Microsoft_Insights_dataCollectionRules_variables_dcrName string
param variables_dcraName string


var dnsPrefix = '${clusterName}-dns'

resource clusterResource 'Microsoft.ContainerService/managedClusters@2022-11-01' = {
  name: clusterName
  location: location
  identity: {
      type: 'SystemAssigned'
    }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: dnsPrefix
    agentPoolProfiles: primaryAgentPoolProfile
    enableRBAC: true
    networkProfile: {
      networkPlugin: networkPlugin
      serviceCidr: serviceCidr
      dockerBridgeCidr: dockerBridgeCidr
    }
    addonProfiles: {
      omsagent: {
        enabled: omsAgentEnabled && !empty(workspaceResourceId)
        config: {
          logAnalyticsWorkspaceResourceID: !empty(workspaceResourceId) ? any(workspaceResourceId) : null
        }
      }
    }
    enableFeatures: [
      'LogAnalytics-ContainerLogV2'
    ]
  }
}

output clusterName string = clusterResource.name

resource variables_clusterName_microsoft_insights_variables_dcra 'Microsoft.ContainerService/managedClusters/providers/dataCollectionRuleAssociations@2021-09-01-preview' = if ('${Prometheusstage}' == 'yes') {
  name: '${variables_clusterName}/microsoft.insights/${variables_dcraName}'
  location: clusterLocation
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
    dataCollectionRuleId: resourceId_Microsoft_Insights_dataCollectionRules_variables_dcrName
  }
}

resource variables_cluster 'Microsoft.ContainerService/managedClusters@2022-07-02-preview' = if ('${Prometheusstage}' == 'yes') { 
  name: variables_clusterName
  location: clusterLocation
  properties: {
    mode: 'Incremental'
    id: clusterResourceId
    azureMonitorProfile: {
      metrics: {
        enabled: true
        kubeStateMetrics: {
          metricLabelsAllowlist: metricLabelsAllowlist
          metricAnnotationsAllowList: metricAnnotationsAllowList
        }
      }
    }
  }
}


