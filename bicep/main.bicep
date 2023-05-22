
param prefix string
param adminUser string
@secure()
param adminPassword string
param agentVMSize string
param dockerBridgeCidr string
param serviceCidr string
param monitoredAKSNetworkPolicy string
param monitoredAKSNetworkPlugin string
param nonMonitoredAKSNetworkPolicy string
param nonMonitoredAKSNetworkPlugin string
param kubernetesVersion string

param workspaceSkuName string
param logAnalyticsWorkspaceName string
param retentionPeriod int

param monitoredClusterName string
param nonmonitoredClusterName string

param managedIdentityName string
param searchTableName string

// custom vent and subnet details param

param monitoredClustervnetName string
param monitoredClustervnetAddressPrefix string
param monitoredClustersubnetName string
param monitoredClustersubnetAddressPrefix string

param nonmonitoredClustervnetName string
param nonmonitoredClustervnetAddressPrefix string
param nonmonitoredClustersubnetName string
param nonmonitoredClustersubnetAddressPrefix string
param azureMonitorWorkspaceName string
param clusterResourceId string 
param actionGroupResourceId string 
param azureMonitorWorkspaceLocation string
param azureMonitorWorkspaceResourceId string 
param clusterLocation string 
param grafanaLocation string 
param grafanaSku string 
param metricAnnotationsAllowList string  
param metricLabelsAllowlist string 
param aksName string 
param grafanaName string 
param groupShortName string 
param PrometheusactionGroup string 
param Receiveremailactiongroups string 
param location string 
param contosoSH360ClusterResourceGroupName string 
param opsResourceGroupName string 
param Prometheusstage string  
param PrometheusworkspaceName string 

var clusterName = aksName
var dcraName = 'MSProm-${clusterLocation}-${clusterName}'

param contributorRoleId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' //contributor role

var resourceGroups = [
  contosoSH360ClusterResourceGroupName
  opsResourceGroupName
]

var monitoredAKSPrimaryAgentPoolProfile = [
  {
    name: 'linuxpool'
    vnetSubnetId: monitoredClustervnet.outputs.vnetSubnetId
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
    vnetSubnetId:monitoredClustervnet.outputs.vnetSubnetId
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
    vnetSubnetId: nonmonitoredClustervnet.outputs.vnetSubnetId
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
// deploy vnet and subnet for monitored cluster

module monitoredClustervnet 'modules/Microsoft.Network/virtualNetworks/vnet.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}vnetDeploy'
  params: {
    location: location
    vnetName: monitoredClustervnetName
    vnetAddressPrefix: monitoredClustervnetAddressPrefix
    subnetName:monitoredClustersubnetName
    subnetAddressPrefix: monitoredClustersubnetAddressPrefix
  }
  dependsOn: [
    rgModule
  ]
}

// deploy vnet and subnet for non monitored cluster

module nonmonitoredClustervnet 'modules/Microsoft.Network/virtualNetworks/vnet.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}vnetDeploynonmonitored'
  params: {
    location: location
    vnetName: nonmonitoredClustervnetName
    vnetAddressPrefix: nonmonitoredClustervnetAddressPrefix
    subnetName:nonmonitoredClustersubnetName
    subnetAddressPrefix: nonmonitoredClustersubnetAddressPrefix
  }
  dependsOn: [
    rgModule
  ]
}

// Monitored AKS cluster deployment
module monitoredAksModule 'modules/Microsoft.ContainerService/managedClusters/aks.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}monitoredAKSDeploy'
  params: {
    location: location
    Prometheusstage: Prometheusstage 
    clusterLocation: clusterLocation 
    clusterName: monitoredClusterName
    clusterResourceId: clusterResourceId
    dockerBridgeCidr: dockerBridgeCidr
    kubernetesVersion: kubernetesVersion
    metricAnnotationsAllowList: metricAnnotationsAllowList
    metricLabelsAllowlist: metricLabelsAllowlist
    networkPlugin: monitoredAKSNetworkPlugin
    networkPolicy: monitoredAKSNetworkPolicy
    primaryAgentPoolProfile: monitoredAKSPrimaryAgentPoolProfile
    serviceCidr: serviceCidr
    variables_clusterName: clusterName 
    resourceId_Microsoft_Insights_dataCollectionRules_variables_dcrName : metricsaddon.outputs.dcrId
    variables_dcraName : dcraName
  }
  dependsOn: [
    rgModule
    monitoredClustervnet
  ]
}

// Non monitored AKS cluster deployment
module nonMonitoredAksModule 'modules/Microsoft.ContainerService/managedClusters/aks.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: '${prefix}nonMonitoredAKSDeploy'
  params: {
    clusterName: nonmonitoredClusterName
    location: location
    omsAgentEnabled: false
    primaryAgentPoolProfile: nonMonitoredAKSPrimaryAgentPoolProfile
    serviceCidr: serviceCidr
    dockerBridgeCidr: dockerBridgeCidr
    networkPlugin: nonMonitoredAKSNetworkPlugin
    networkPolicy: nonMonitoredAKSNetworkPolicy
    kubernetesVersion: kubernetesVersion
    clusterLocation: clusterLocation
    clusterResourceId  : clusterResourceId
    metricAnnotationsAllowList: metricAnnotationsAllowList
    metricLabelsAllowlist: metricLabelsAllowlist
    Prometheusstage: Prometheusstage
    resourceId_Microsoft_Insights_dataCollectionRules_variables_dcrName: metricsaddon.outputs.dcrId
    variables_clusterName: clusterName
    variables_dcraName: dcraName
  }
  dependsOn: [
    rgModule
    nonmonitoredClustervnet
  ]
}

// Azure monitor workspace Deployment 
module azuremonitorworkspace 'modules/Microsoft.Monitor/azureMonitorWorkspace.bicep'  = if ('${Prometheusstage}' == 'yes') {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: 'workspaceDeploy'
  params: {
    PrometheusworkspaceName: azureMonitorWorkspaceName
    location: location
  }
  dependsOn: [
    rgModule
  ]
}
// Action Group Deployment 
module actiongroup 'modules/Microsoft.AlertsManagement/actiongroup.bicep' = if ('${Prometheusstage}' == 'yes') {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: 'actiongp'
  params: {
    groupShortName: groupShortName
    PrometheusactionGroup: PrometheusactionGroup
    Receiveremailactiongroups: Receiveremailactiongroups
  }
  dependsOn: [
    rgModule
    azuremonitorworkspace
  ]
}

// Prometheus Rule Groups "Alerts Rules and Recordeing Rules" Deployment 
module workspacealerts 'modules/Microsoft.AlertsManagement/prometheusRuleGroups.bicep' = if ('${Prometheusstage}' == 'yes')  {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: 'workspacealertsrules'
  params: {
    location: location
    aksName: aksName
    actionGroupResourceId: actionGroupResourceId
    azureMonitorWorkspaceLocation: azureMonitorWorkspaceLocation
    azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
    PrometheusworkspaceName : azureMonitorWorkspaceName 
  } 
  dependsOn: [
    rgModule
    metricsaddon
    actiongroup
  ]
}

// Data Collection Rules for Azure monitore workspace 
module metricsaddon 'modules/Microsoft.OperationalInsights/dataCollectionRule/dataCollectionRulePrometheus.bicep' =  {
  scope: resourceGroup(opsResourceGroupName)
  name: 'prometheusmetrics'
  params: {
    aksName: aksName
    azureMonitorWorkspaceLocation: azureMonitorWorkspaceLocation
    azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
  }
   dependsOn: [
    rgModule
    azuremonitorworkspace
  ]
}
 
// Link Grafana to Azure Monitore Workspace 
module grafana 'modules/Microsoft.Grafana/grafana.bicep' = if ('${Prometheusstage}' == 'yes') {
  scope: resourceGroup(opsResourceGroupName)
  name: 'linkgrafana'
  params: {
    azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
    grafanaLocation: grafanaLocation
    grafanaName: grafanaName
    grafanaSku: grafanaSku
  }
  dependsOn: [
    rgModule
    azuremonitorworkspace
  ]
}

