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


targetScope = 'subscription'

// Azure monitor workspace Deployment 
module azuremonitorworkspace 'modules/Microsoft.Monitor/azureMonitorWorkspace.bicep'  = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: 'workspaceDeploy'
  params: {
    PrometheusworkspaceName: azureMonitorWorkspaceName
    location: location
  }
  dependsOn: [
    
  ]
}
// Action Group Deployment 
module actiongroup 'modules/Microsoft.Insights/actionGroups.bicep' = {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: 'actiongp'
  params: {
    groupShortName: groupShortName
    PrometheusactionGroup: PrometheusactionGroup
    Receiveremailactiongroups: Receiveremailactiongroups
  }
  dependsOn: [
    azuremonitorworkspace
  ]
}

// Prometheus Rule Groups "Alerts Rules and Recordeing Rules" Deployment 
module RuleGroups 'modules/Microsoft.AlertsManagement/prometheusRuleGroups.bicep' =  {
  scope: resourceGroup(contosoSH360ClusterResourceGroupName)
  name: 'workspacerulegroups'
  params: {
    location: location
    aksName: aksName
    azureMonitorWorkspaceName: azureMonitorWorkspaceName
    actionGroupResourceId: actionGroupResourceId
    azureMonitorWorkspaceLocation: azureMonitorWorkspaceLocation
    azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
  } 
  dependsOn: [
    datacollectionrule
    actiongroup
  ]
}

// Data Collection Rules for Azure monitore workspace 
module datacollectionrule 'modules/Microsoft.Insights/dataCollectionRule/dataCollectionRulesPromethus.bicep' =  {
  scope: resourceGroup(opsResourceGroupName)
  name: 'prometheusmetrics'
   params: {
    aksName: aksName
    azureMonitorWorkspaceLocation: azureMonitorWorkspaceLocation
    azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
    }
   dependsOn: [

    azuremonitorworkspace
  ]
}
module dataCollectionRuleAssociationprometheus 'modules/Microsoft.ContainerService/managedClusters/dataCollectionRuleAssociations/dataCollectionRuleAssociations.bicep'= {
  name: 'azuremonitormetrics-dcra-${uniqueString(clusterResourceId)}'
  scope: resourceGroup(clusterSubscriptionId, clusterResourceGroup)
  params: {
    resourceId_Microsoft_Insights_dataCollectionRules_variables_dcrName: datacollectionrule.outputs.dcrId
    variables_clusterName: clusterName
    variables_dcraName: dcraName
    clusterLocation: clusterLocation
  }
}
// Azure Monitore workpsace metrics Add-on 
module azuremonitormetrics_profile_prometheus 'modules/Microsoft.ContainerService/managedClusters/metricsAddonprometheus.bicep' = {
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
    dataCollectionRuleAssociationprometheus
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
    azuremonitorworkspace
  ]
}

