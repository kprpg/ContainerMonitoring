param location string
param prefix string
param adminUser string
@secure()
param adminPassword string
param servicePrincipalClientId string
@secure()
param servicePrincipalClientSecret string
param agentVMSize string
param dockerBridgeCidr string
param serviceCidr string
param monitoredAKSNetworkPolicy string
param monitoredAKSNetworkPlugin string
param nonMonitoredAKSNetworkPolicy string
param nonMonitoredAKSNetworkPlugin string
param kubernetesVersion string

param workspaceSkuName string
param contosoSH360ClusterResourceGroupName string
param opsResourceGroupName string
param logAnalyticsWorkspaceName string
param retentionPeriod int

param monitoredClusterName string
param nonmonitoredClusterName string

param managedIdentityName string
param searchTableName string

param contributorRoleId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' //contributor role

var resourceGroups = [
  contosoSH360ClusterResourceGroupName
  opsResourceGroupName
]

var monitoredAKSPrimaryAgentPoolProfile = [
  {
    name: 'linuxpool'
    osDiskSizeGB: 120
    count: 2
    vmSize: agentVMSize
    osType: 'Linux'
    enableAutoScaling: true
    type: 'VirtualMachineScaleSets'
    storageProfile: 'ManagedDisks'
    minCount: 2
    maxCount: 2
    mode: 'System'
  }
  {
    name: 'window'
    osDiskSizeGB: 120
    count: 1
    vmSize: agentVMSize
    osType: 'Windows'
    enableAutoScaling: true
    type: 'VirtualMachineScaleSets'
    storageProfile: 'ManagedDisks'
    minCount: 1
    maxCount: 1
    maxPods: 30
  }
]

var nonMonitoredAKSPrimaryAgentPoolProfile = [
  {
    name: 'linuxpool'
    osDiskSizeGB: 120
    count: 3
    vmSize: agentVMSize
    osType: 'Linux'
    enableAutoScaling: true
    storageProfile: 'ManagedDisks'
    type: 'VirtualMachineScaleSets'
    minCount: 2
    maxCount: 3
    mode: 'System'

  }
]

targetScope = 'subscription'

// AKS cluster Resource group and workspace Resource group deployment 
module rgModule 'modules/Microsoft.Resources/resourceGroups/resourceGroup.bicep' = [for resourceGroup in resourceGroups: {
  name: 'rgDeploy${resourceGroup}'
  params: {
    resourceGroupName: resourceGroup
    location: location
  }
}]

//Log analytics workspace deployment
module workspaceModule 'modules/Microsoft.OperationalInsights/workspaces/logAnalyticsWorkspace.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}workspaceDeploy'
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
    workspaceSkuName: workspaceSkuName
    retentionPeriod: retentionPeriod    
  }
  dependsOn: [
    rgModule
  ]
}

// Saved Searches Deployment
module logAnalyticsWorkspaceSavedSearches 'modules/Microsoft.OperationalInsights/workspaces/savedSearch/workspaceSavedSearch.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}savedSearch'
  params: {
    workspaceName: workspaceModule.outputs.workspaceName
  }
}

// Search table deployment 
module searchTableModule 'modules/Microsoft.OperationalInsights/workspaces/searchTable/searchTable.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}SearchTable'
  params: {
    workspaceName: workspaceModule.outputs.workspaceName
  }
  dependsOn: [
    logAnalyticsWorkspaceSavedSearches
  ]
}
// Create an User assigned managed identity
module userAssignedIdentityModule 'modules/Microsoft.ManagedIdentity/userAssignedIdentities/userAssignedIdentity.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}userMI'
  params: {
    location: location
    managedIdentityName: managedIdentityName
    roleId: contributorRoleId
  }
  dependsOn: [
    rgModule
    logAnalyticsWorkspaceSavedSearches
  ]
}

// Search Job Table Deployment
module workspaceSearchTable 'modules/Microsoft.OperationalInsights/workspaces/searchTable/workspaceSearchTable.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}searchTableScript'
  params: {
    location: location
    managedIdentityName: userAssignedIdentityModule.outputs.name
    resourceGroupName: opsResourceGroupName
    searchTableName: searchTableName
    workspaceName: workspaceModule.outputs.workspaceName
  }
  dependsOn: [
    searchTableModule
  ]
}


// Monitored AKS cluster deployment
module monitoredAksModule 'modules/Microsoft.ContainerService/managedClusters/aks.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}monitoredAKSDeploy'
  params: {
    clusterName: monitoredClusterName
    location: location
    servicePrincipalClientId: servicePrincipalClientId
    servicePrincipalClientSecret: servicePrincipalClientSecret
    workspaceResourceId: workspaceModule.outputs.workspaceId
    omsAgentEnabled: true
    primaryAgentPoolProfile: monitoredAKSPrimaryAgentPoolProfile
    serviceCidr: serviceCidr
    dockerBridgeCidr: dockerBridgeCidr
    networkPlugin: monitoredAKSNetworkPlugin
    networkPolicy: monitoredAKSNetworkPolicy
    kubernetesVersion: kubernetesVersion
  }
  dependsOn: [
    rgModule
  ]
}

// Non monitored AKS cluster deployment
module nonMonitoredAksModule 'modules/Microsoft.ContainerService/managedClusters/aks.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}nonMonitoredAKSDeploy'
  params: {
    clusterName: nonmonitoredClusterName
    location: location
    servicePrincipalClientId: servicePrincipalClientId
    servicePrincipalClientSecret: servicePrincipalClientSecret
    omsAgentEnabled: false
    primaryAgentPoolProfile: nonMonitoredAKSPrimaryAgentPoolProfile
    serviceCidr: serviceCidr
    dockerBridgeCidr: dockerBridgeCidr
    networkPlugin: nonMonitoredAKSNetworkPlugin
    networkPolicy: nonMonitoredAKSNetworkPolicy
    kubernetesVersion: kubernetesVersion
  }
  dependsOn: [
    rgModule
  ]
}

