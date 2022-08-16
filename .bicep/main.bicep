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

var savedSearches = [
  {
    category: 'Container Insights'
    displayName: 'CPU usage by Namespace'
    query: 'KubePodInventory\r\n| where isnotempty(Computer)\r\n// eliminate unscheduled pods\r\n| where PodStatus in (\'Running\',\'Unknown\')\r\n| summarize by bin(TimeGenerated, 1m), Computer, ClusterId, ContainerName, Namespace\r\n| project TimeGenerated, InstanceName = strcat(ClusterId, \'/\', ContainerName), Namespace\r\n| join\r\n(\r\n    Perf\r\n    | where ObjectName == \'K8SContainer\'\r\n    | where CounterName == \'cpuUsageNanoCores\'\r\n    | summarize UsageValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\r\n    | project-away CounterName\r\n    | join kind = fullouter\r\n    (\r\n        Perf\r\n        | where ObjectName == \'K8SContainer\'\r\n        | where CounterName == \'cpuRequestNanoCores\'\r\n        | summarize RequestValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\r\n        | project-away CounterName\r\n    )\r\n    on Computer, InstanceName, TimeGenerated\r\n    | project TimeGenerated = iif(isnotempty(TimeGenerated), TimeGenerated, TimeGenerated1),   Computer = iif(isnotempty(Computer), Computer, Computer1),  InstanceName = iif(isnotempty(InstanceName), InstanceName, InstanceName1),  UsageValue = iif(isnotempty(UsageValue), UsageValue, 0.0),   RequestValue = iif(isnotempty(RequestValue), RequestValue, 0.0)\r\n    | extend ConsumedValue = iif(UsageValue > RequestValue, UsageValue, RequestValue)\r\n)\r\non InstanceName, TimeGenerated\r\n| summarize TotalCpuConsumedCores = sum(ConsumedValue) / 60 / 1000000 by bin(TimeGenerated, 1h), Namespace\r\n| render piechart'
  }
  {
    category: 'Container Insights'
    displayName: 'Disk RPS per disk per node'
    query: 'InsightsMetrics\r\n| where Namespace == \'container.azm.ms/diskio\'\r\n| where TimeGenerated > ago(1h)\r\n| where Name == \'reads\'\r\n| extend Tags = todynamic(Tags)\r\n| extend HostName = tostring(Tags.hostName), Device = Tags.name\r\n| extend NodeDisk = strcat(Device, "/", HostName)\r\n| order by NodeDisk asc, TimeGenerated asc\r\n| serialize\r\n| extend PrevVal = iif(prev(NodeDisk) != NodeDisk, 0.0, prev(Val)), PrevTimeGenerated = iif(prev(NodeDisk) != NodeDisk, datetime(null), prev(TimeGenerated))\r\n| where isnotnull(PrevTimeGenerated) and PrevTimeGenerated != TimeGenerated\r\n| extend Rate = iif(PrevVal > Val, Val / (datetime_diff(\'Second\', TimeGenerated, PrevTimeGenerated) * 1), iif(PrevVal == Val, 0.0, (Val - PrevVal) / (datetime_diff(\'Second\', TimeGenerated, PrevTimeGenerated) * 1)))\r\n| where isnotnull(Rate)\r\n| project TimeGenerated, NodeDisk, Rate\r\n| render timechart'
  }
  {
    category: 'Container Insights'
    displayName: 'KubeEvents Insights by Reason'
    query: 'KubeEvents\r\n| summarize count() by Message\r\n| render columnchart'
  }
  {
    category: 'Container Insights'
    displayName: 'Logs contains Failure or Error or Exception'
    query: 'ContainerLog\r\n| where TimeGenerated > ago(30m)\r\n| where (LogEntry contains "failed" or LogEntry contains "error" or LogEntry contains "exception")\r\n| project TimeGenerated, LogEntry, ContainerID, Computer'
  }
  {
    category: 'Container Insights'
    displayName: 'Memory usage by Namespace'
    query: '// ********************\r\n// memory usage\r\n// ********************\r\nKubePodInventory\r\n//| where ClusterName == \'contosoretail2\'\r\n| where isnotempty(Computer)\r\n// eliminate unscheduled pods\r\n| where PodStatus in (\'Running\',\'Unknown\')\r\n| summarize by bin(TimeGenerated, 1m), Computer, ClusterId, ContainerName, Namespace\r\n| project TimeGenerated, InstanceName = strcat(ClusterId, \'/\', ContainerName), Namespace\r\n| join\r\n(\r\n    Perf\r\n    | where ObjectName == \'K8SContainer\'\r\n    | where CounterName == \'memoryRssBytes\'\r\n    | summarize UsageValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\r\n    | project-away CounterName\r\n    | join kind = fullouter\r\n    (\r\n        Perf\r\n        | where ObjectName == \'K8SContainer\'\r\n        | where CounterName == \'memoryRequestBytes\'\r\n        | summarize RequestValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\r\n        | project-away CounterName\r\n    )\r\n    on Computer, InstanceName, TimeGenerated\r\n    | project TimeGenerated = iif(isnotempty(TimeGenerated), TimeGenerated, TimeGenerated1), Computer = iif(isnotempty(Computer), Computer, Computer1), InstanceName = iif(isnotempty(InstanceName), InstanceName, InstanceName1), UsageValue = iif(isnotempty(UsageValue), UsageValue, 0.0), RequestValue = iif(isnotempty(RequestValue), RequestValue, 0.0)\r\n    | extend ConsumedValue = iif(UsageValue > RequestValue, UsageValue, RequestValue)\r\n)\r\non InstanceName, TimeGenerated\r\n| summarize TotalMemoryConsumedMb = sum(ConsumedValue)/60/1024/1024 by bin(TimeGenerated, 1h), Namespace\r\n| render timechart'
  }
]


targetScope = 'subscription'

// AKS cluster Resource group and workspace Resource group deployment 
module rgModule 'modules/Microsoft.Resources/resourceGroups/deploy.bicep' = [for resourceGroup in resourceGroups: {
  scope: subscription(subscriptionId)
  name: 'rgDeploy${resourceGroup}'
  params: {
    name: resourceGroup
    location: location
  }
}]

//Log analytics workspace deployment with saved searches
module workspaceModule 'modules/Microsoft.OperationalInsights/workspaces/deploy.bicep' = {
  scope: resourceGroup(opsResourceGroupName)
  name: '${prefix}workspaceDeploy'
  params: {
    name: logAnalyticsWorkspaceName
    serviceTier: workspaceSkuName
    savedSearches: savedSearches
  }
  dependsOn: [
    rgModule
  ]
}

