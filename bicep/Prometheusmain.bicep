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

var clusterName = aksName
var dcraName = 'MSProm-${clusterLocation}-${clusterName}'
var clusterSubscriptionId = azureSubscriptionId
var clusterResourceGroup = resourceGroupName

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


// Azure monitor workspace Deployment 
module azuremonitorworkspace 'modules/Microsoft.Monitor/azureMonitorWorkspace.bicep'  = {
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
module actiongroup 'modules/Microsoft.AlertsManagement/actiongroup.bicep' = {
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
module workspacealerts 'modules/Microsoft.AlertsManagement/prometheusRuleGroups.bicep' =  {
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

module azuremonitormetrics_dcra_clusterResourceId 'modules/Microsoft.OperationalInsights/dataCollectionRule/nested_azuremonitormetrics_dcra_clusterResourceId.bicep' = {
  name: 'azuremonitormetrics-dcra-${uniqueString(clusterResourceId)}'
  scope: resourceGroup(clusterSubscriptionId, clusterResourceGroup)
  params: {
    resourceId_Microsoft_Insights_dataCollectionRules_variables_dcrName: metricsaddon.outputs.dcrId
    variables_clusterName: clusterName
    variables_dcraName: dcraName
    clusterLocation: clusterLocation
  }
}

// Azure Monitore workpsace metrics Add-on 
module azuremonitormetrics_profile_clusterResourceId 'modules/Microsoft.OperationalInsights/dataCollectionRule/nested_azuremonitormetrics_profile_clusterResourceId.bicep'= {
  name: 'azuremonitormetrics-profile--${uniqueString(clusterResourceId)}'
  scope: resourceGroup(clusterSubscriptionId, clusterResourceGroup)
  params: {
    variables_clusterName: clusterName
    clusterLocation: clusterLocation
    clusterResourceId: clusterResourceId
    metricLabelsAllowlist: metricLabelsAllowlist
    metricAnnotationsAllowList: metricAnnotationsAllowList
  }
  dependsOn: [
    azuremonitormetrics_dcra_clusterResourceId
  ]
}

// Link Grafana to Azure Monitore Workspace 
module grafana 'modules/Microsoft.Grafana/grafana.bicep' = {
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

