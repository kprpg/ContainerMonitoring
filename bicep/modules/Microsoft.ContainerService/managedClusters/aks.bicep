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
    aadProfile: {
      managed: true
      tenantID: tenant().tenantId
      enableAzureRBAC: true
    }
    enableFeatures: [
      'LogAnalytics-ContainerLogV2'
    ]
  }
}

output clusterName string = clusterResource.name
