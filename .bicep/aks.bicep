param location string
param clusterName string
param primaryAgentPoolProfile array
param servicePrincipalClientId string
@secure()
param servicePrincipalClientSecret string
param workspaceResourceId string = ''
param omsAgentEnabled bool = true
param adminUser string
@secure()
param adminPassword string

var dnsPrefix = '${clusterName}-dns'

resource clusterResource 'Microsoft.ContainerService/managedClusters@2022-01-01' = {
  name: clusterName
  location: location
  properties: {
    kubernetesVersion: '1.23.5'
    dnsPrefix: dnsPrefix
    agentPoolProfiles: primaryAgentPoolProfile
    servicePrincipalProfile: {
      clientId: servicePrincipalClientId
      Secret: servicePrincipalClientSecret
    }
    windowsProfile: {
      adminUsername: adminUser
      adminPassword: adminPassword
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '10.0.0.0/16'
      dockerBridgeCidr: '172.17.0.1/16'
    }
    addonProfiles: {
      omsagent: {
        enabled: omsAgentEnabled && !empty(workspaceResourceId)
        config: {
          logAnalyticsWorkspaceResourceID: !empty(workspaceResourceId) ? any(workspaceResourceId) : null
        }
      }
    }
  }
}

output clusterName string = clusterResource.name
