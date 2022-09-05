param location string
param prefix string
param adminUser string
@secure()
param adminPassword string
param servicePrincipalClientId string
@secure()
param servicePrincipalClientSecret string
param agentVMSize string

param workspaceSkuName string
param contosoSH360ClusterResourceGroupName string
param opsResourceGroupName string
param logAnalyticsWorkspaceName string
param montioredClusterName string
param nonMontioredClusterName string

var resourceGroups = [
  contosoSH360ClusterResourceGroupName
  opsResourceGroupName
]

var monitoredAKSPrimaryAgentPoolProfile = [
  {
    name: 'linux'
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
module rgModule 'modules/resourceGroup.bicep' = [for resourceGroup in resourceGroups: {
  name: 'rgDeploy${resourceGroup}'
  params: {
    resourceGroupName: resourceGroup
    location: location
  }
}]

//Log analytics workspace deployment
module workspaceModule 'modules/logAnalyticsWorkspace.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}workspaceDeploy'
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
    workspaceSkuName: workspaceSkuName
  }
  dependsOn: [
    rgModule
  ]
}

// Saved Searches Deployment
module savedSearchModule 'modules/workspaceSavedSearches.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}savedSearchesDeploy'
  params: {
    workspaceName: workspaceModule.outputs.workspaceName
  }
  dependsOn: [
    workspaceModule
  ]
}

// Monitored AKS cluster deployment
module monitoredAksModule 'modules/aks.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}monitoredAKSDeploy'
  params: {
    clusterName: montioredClusterName
    location: location
    servicePrincipalClientId: servicePrincipalClientId
    servicePrincipalClientSecret: servicePrincipalClientSecret
    workspaceResourceId: workspaceModule.outputs.workspaceId
    omsAgentEnabled: true
    primaryAgentPoolProfile: monitoredAKSPrimaryAgentPoolProfile
    adminUser: adminUser
    adminPassword: adminPassword
  }
}

// Non monitored AKS cluster deployment
module nonMonitoredAksModule 'modules/aks.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}nonMonitoredAKSDeploy'
  params: {
    clusterName: nonMontioredClusterName
    location: location
    servicePrincipalClientId: servicePrincipalClientId
    servicePrincipalClientSecret: servicePrincipalClientSecret
    omsAgentEnabled: false
    primaryAgentPoolProfile: nonMonitoredAKSPrimaryAgentPoolProfile
    adminUser: adminUser
    adminPassword: adminPassword
  }
  dependsOn: [
    monitoredAksModule
  ]
}
