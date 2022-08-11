param subscriptionId string
param location string
param prefix string

param contosoSH360ClusterResourceGroupName string
param opsResourceGroupName string
param logAnalyticsWorkspaceName string
param montioredClusterName string
param nonMontioredClusterName string

param servicePrincipalClientId string
@secure()
param servicePrincipalClientSecret string
param agentVMSize string
param adminUser string
@secure()
param adminPassword string
@secure()
param contosoSH360ClusterSPObjectId string
param workspaceSkuName string

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
module rgModule '.bicep/resourceGroup.bicep' = [for resourceGroup in resourceGroups: {
  scope: subscription(subscriptionId)
  name: 'rgDeploy${resourceGroup}'
  params: {
    resourceGroupName: resourceGroup
    location: location
  }
}]

//Log analytics workspace deployment
module workspaceModule '.bicep/logAnalyticsWorkspace.bicep' = {
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
module savedSearchModule '.bicep/workspaceSavedSearches.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}savedSearchesDeploy'
  params: {
    workspaceName: workspaceModule.outputs.workspaceName
  }
}

// Monitored AKS cluster deployment
module monitoredAksModule '.bicep/aks.bicep' = {
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

// Monitoring Metrics Publisher Role assignment to Cluster Service principal
module roleAssignmentModule '.bicep/roleAssignment.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}roleAssignmentDeploy'
  params: {
    clusterName: monitoredAksModule.outputs.clusterName
    ContosoSH360ClusterSPObjectId: contosoSH360ClusterSPObjectId
  }
}

// Non monitored AKS cluster deployment
module nonMonitoredAksModule '.bicep/aks.bicep' = {
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
