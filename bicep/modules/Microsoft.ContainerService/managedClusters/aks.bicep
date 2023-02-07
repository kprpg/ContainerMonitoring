param location string
param clusterName string
param primaryAgentPoolProfile array
param servicePrincipalClientId string
@secure()
param servicePrincipalClientSecret string
param workspaceResourceId string = ''
param omsAgentEnabled bool = true
param dockerBridgeCidr string
param serviceCidr string
param networkPolicy string
param networkPlugin string
param kubernetesVersion string

var dnsPrefix = '${clusterName}-dns'

resource clusterResource 'Microsoft.ContainerService/managedClusters@2021-02-01' = {
  name: clusterName
  location: location
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: dnsPrefix
    agentPoolProfiles: primaryAgentPoolProfile
    servicePrincipalProfile: {
      clientId: servicePrincipalClientId
      secret: servicePrincipalClientSecret
    }
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
      managed: false
      tenantID: tenant().tenantId
      enableAzureRBAC: false
    }
  }
}

output clusterName string = clusterResource.name
