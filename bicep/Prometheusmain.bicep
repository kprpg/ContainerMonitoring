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
param azureSubscriptionId string 
param grafanaName string 
param groupShortName string 
param PrometheusactionGroup string 
param Receiveremailactiongroups string 
param resourceGroupName string 
param location string 
param contosoSH360ClusterResourceGroupName string 
param opsResourceGroupName string 

var resourceGroups = [
  contosoSH360ClusterResourceGroupName
  opsResourceGroupName
]

targetScope = 'subscription'

module rgModule 'modules/Microsoft.Resources/resourceGroups/resourceGroup.bicep' = [for resourceGroup in resourceGroups: {
  name: 'rgDeploy${resourceGroup}'
  params: {
    resourceGroupName: resourceGroup
    location: location
  }
}]


// Azure monitor workspace deployment 

module azuremointerworkspace 'modules/Microsoft.Monitor/azureMonitorWorkspace.bicep'  = {
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

module actiongroup 'modules/Microsoft.insights/Actiongroup.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: 'actiongp'
  params: {
    groupShortName: groupShortName
    PrometheusactionGroup: PrometheusactionGroup
    Receiveremailactiongroups: Receiveremailactiongroups
  }
  dependsOn: [
    rgModule
    azuremointerworkspace

  ]
}

module workspacealerts 'modules/Microsoft.insights/prometheusRuleGroups.bicep' =  {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: 'workspacealertsrules'
  params: {
    location: location
    aksName: aksName
    azureMonitorWorkspaceName: azureMonitorWorkspaceName
    actionGroupResourceId: actionGroupResourceId
    azureMonitorWorkspaceLocation: azureMonitorWorkspaceLocation
    azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
  } 
  dependsOn: [
    rgModule
    metricsaddon
    actiongroup
  ]
}

module metricsaddon 'modules/Microsoft.OperationalInsights/dataCollectionRule/FullAzureMonitorMetricsProfile.bicep' =  {
  scope: resourceGroup(opsResourceGroupName)
  name: 'prometheusmetrics'
  params: {
    azureMonitorWorkspaceLocation: azureMonitorWorkspaceLocation
    azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
    clusterLocation: clusterLocation
    clusterResourceId: clusterResourceId
    grafanaLocation: grafanaLocation
    azureSubscriptionId  : azureSubscriptionId
    resourceGroupName  : resourceGroupName
    aksName  : aksName
    grafanaName : grafanaName
    grafanaSku: grafanaSku
    metricAnnotationsAllowList: metricAnnotationsAllowList
    metricLabelsAllowlist: metricLabelsAllowlist
  }
  dependsOn: [
    rgModule
    azuremointerworkspace
    actiongroup
  ]
}
