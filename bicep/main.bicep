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

param workspaceSkuName string
param contosoSH360ClusterResourceGroupName string
param logAnalyticsWorkspaceName string
param monitoredClusterName string

var resourceGroups = [
  contosoSH360ClusterResourceGroupName
]

var savedSearches = [
  {
    name: 'ListAllPods'
    category: 'Container Logs'
    displayName: 'List pods by namespace'
    query: '//List all Pods connected to your LA workspace\r\nKubePodInventory\r\n| project ClusterName,PodName=Name,Namespace,PodStatus,PodStartTime,PodRestartCount,PodCreationTimeStamp\r\n//| where PodName contains "azure-vote"\r\n| distinct ClusterName,PodName,Namespace,PodStatus,PodStartTime,PodRestartCount,PodCreationTimeStamp'
  }
  {
    name: 'ListUnscheduledPods'
    category: 'Container Insights'
    displayName: 'List unscheduled pods'
    query: '//List all Pods not in running state\r\nKubePodInventory\r\n| project ClusterName,PodName=Name,Namespace,PodStatus,PodStartTime,PodRestartCount,PodCreationTimeStamp\r\n//| where Namespace == "azure-vote"\r\n| where PodStatus != "Running"\r\n| distinct ClusterName,PodName,Namespace,PodStatus,PodStartTime,PodRestartCount,PodCreationTimeStamp'
  }
  {
    name: 'ReasonforUnscheduledPods'
    category: 'Container Insights'
    displayName: 'Reason for unscheduled pods'
    query: '//Find cause for unscheduled pods\r\nKubeEvents\r\n//| project Name, ObjectKind, KubeEventType, Reason, Message, Namespace\r\n| where ObjectKind =~ "Pod"\r\n| where Namespace =~ "azure-vote"\r\n| distinct Name, ObjectKind, KubeEventType, Reason, Message, Namespace'
  }
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
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
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
module logAnalyticsWorkspaceSavedSearches 'modules/Microsoft.OperationalInsights/workspaces/savedSearch/workspaceSavedSearch.bicep' = [for (savedSearch, index) in savedSearches: {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${uniqueString(deployment().name)}-LAW-SavedSearch-${index}'
  params: {
    workspaceName: workspaceModule.outputs.workspaceName
    name: '${savedSearch.name}${uniqueString(deployment().name)}'
    etag: contains(savedSearch, 'eTag') ? savedSearch.etag : '*'
    displayName: savedSearch.displayName
    category: savedSearch.category
    query: savedSearch.query
  }
}]

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
    adminUser: adminUser
    adminPassword: adminPassword
    serviceCidr: serviceCidr
    dockerBridgeCidr: dockerBridgeCidr
  }
}
