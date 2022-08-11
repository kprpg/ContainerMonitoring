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

module rgModule '.bicep/resourceGroup.bicep' = [for resourceGroup in resourceGroups: {
  scope: subscription(subscriptionId)
  name: 'rgDeploy${resourceGroup}'
  params: {
    resourceGroupName: resourceGroup
    location: location
  }
}]

module workspaceModule '.bicep/logAnalyticsWorkspace.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}workspaceDeploy'
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
  }
  dependsOn: [
    rgModule
  ]
}

module savedSearchModule '.bicep/workspaceSavedSearches.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}savedSearchesDeploy'
  params: {
    workspaceName: workspaceModule.outputs.workspaceName
  }
}

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

module roleAssignmentModule '.bicep/roleAssignment.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}roleAssignmentDeploy'
  params: {
    clusterName: monitoredAksModule.outputs.clusterName
    ContosoSH360ClusterSPObjectId: contosoSH360ClusterSPObjectId
  }
}

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
