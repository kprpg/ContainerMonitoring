param workspaceName string

var savedSearches = [
  {
    name: 'CPUUsageByNamespace'
    category: 'Container Insights'
    displayName: 'CPU usage by Namespace'
    query: 'KubePodInventory\r\n| where isnotempty(Computer)\r\n// eliminate unscheduled pods\r\n| where PodStatus in (\'Running\',\'Unknown\')\r\n| summarize by bin(TimeGenerated, 1m), Computer, ClusterId, ContainerName, Namespace\r\n| project TimeGenerated, InstanceName = strcat(ClusterId, \'/\', ContainerName), Namespace\r\n| join\r\n(\r\n    Perf\r\n    | where ObjectName == \'K8SContainer\'\r\n    | where CounterName == \'cpuUsageNanoCores\'\r\n    | summarize UsageValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\r\n    | project-away CounterName\r\n    | join kind = fullouter\r\n    (\r\n        Perf\r\n        | where ObjectName == \'K8SContainer\'\r\n        | where CounterName == \'cpuRequestNanoCores\'\r\n        | summarize RequestValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\r\n        | project-away CounterName\r\n    )\r\n    on Computer, InstanceName, TimeGenerated\r\n    | project TimeGenerated = iif(isnotempty(TimeGenerated), TimeGenerated, TimeGenerated1),   Computer = iif(isnotempty(Computer), Computer, Computer1),  InstanceName = iif(isnotempty(InstanceName), InstanceName, InstanceName1),  UsageValue = iif(isnotempty(UsageValue), UsageValue, 0.0),   RequestValue = iif(isnotempty(RequestValue), RequestValue, 0.0)\r\n    | extend ConsumedValue = iif(UsageValue > RequestValue, UsageValue, RequestValue)\r\n)\r\non InstanceName, TimeGenerated\r\n| summarize TotalCpuConsumedCores = sum(ConsumedValue) / 60 / 1000000 by bin(TimeGenerated, 1h), Namespace\r\n| render piechart'
  }
  {
    name: 'DiskRPSPerDiskPerNode'
    category: 'Container Insights'
    displayName: 'Disk RPS per disk per node'
    query: 'InsightsMetrics\r\n| where Namespace == \'container.azm.ms/diskio\'\r\n| where TimeGenerated > ago(1h)\r\n| where Name == \'reads\'\r\n| extend Tags = todynamic(Tags)\r\n| extend HostName = tostring(Tags.hostName), Device = Tags.name\r\n| extend NodeDisk = strcat(Device, "/", HostName)\r\n| order by NodeDisk asc, TimeGenerated asc\r\n| serialize\r\n| extend PrevVal = iif(prev(NodeDisk) != NodeDisk, 0.0, prev(Val)), PrevTimeGenerated = iif(prev(NodeDisk) != NodeDisk, datetime(null), prev(TimeGenerated))\r\n| where isnotnull(PrevTimeGenerated) and PrevTimeGenerated != TimeGenerated\r\n| extend Rate = iif(PrevVal > Val, Val / (datetime_diff(\'Second\', TimeGenerated, PrevTimeGenerated) * 1), iif(PrevVal == Val, 0.0, (Val - PrevVal) / (datetime_diff(\'Second\', TimeGenerated, PrevTimeGenerated) * 1)))\r\n| where isnotnull(Rate)\r\n| project TimeGenerated, NodeDisk, Rate\r\n| render timechart'
  }
  {
    name: 'KubeEventsInsightsByReason'
    category: 'Container Insights'
    displayName: 'KubeEvents Insights by Reason'
    query: 'KubeEvents\r\n| summarize count() by Message\r\n| render columnchart'
  }
  {
    name: 'LogsContainsFailureOrErrorOrException'
    category: 'Container Insights'
    displayName: 'Logs contains Failure or Error or Exception'
    query: 'ContainerLog\r\n| where TimeGenerated > ago(30m)\r\n| where (LogEntry contains "failed" or LogEntry contains "error" or LogEntry contains "exception")\r\n| project TimeGenerated, LogEntry, ContainerID, Computer'
  }
  {
    name: 'MemoryUsageByNamespace'
    category: 'Container Insights'
    displayName: 'Memory usage by Namespace'
    query: '// ********************\r\n// memory usage\r\n// ********************\r\nKubePodInventory\r\n//| where ClusterName == \'contosoretail2\'\r\n| where isnotempty(Computer)\r\n// eliminate unscheduled pods\r\n| where PodStatus in (\'Running\',\'Unknown\')\r\n| summarize by bin(TimeGenerated, 1m), Computer, ClusterId, ContainerName, Namespace\r\n| project TimeGenerated, InstanceName = strcat(ClusterId, \'/\', ContainerName), Namespace\r\n| join\r\n(\r\n    Perf\r\n    | where ObjectName == \'K8SContainer\'\r\n    | where CounterName == \'memoryRssBytes\'\r\n    | summarize UsageValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\r\n    | project-away CounterName\r\n    | join kind = fullouter\r\n    (\r\n        Perf\r\n        | where ObjectName == \'K8SContainer\'\r\n        | where CounterName == \'memoryRequestBytes\'\r\n        | summarize RequestValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\r\n        | project-away CounterName\r\n    )\r\n    on Computer, InstanceName, TimeGenerated\r\n    | project TimeGenerated = iif(isnotempty(TimeGenerated), TimeGenerated, TimeGenerated1), Computer = iif(isnotempty(Computer), Computer, Computer1), InstanceName = iif(isnotempty(InstanceName), InstanceName, InstanceName1), UsageValue = iif(isnotempty(UsageValue), UsageValue, 0.0), RequestValue = iif(isnotempty(RequestValue), RequestValue, 0.0)\r\n    | extend ConsumedValue = iif(UsageValue > RequestValue, UsageValue, RequestValue)\r\n)\r\non InstanceName, TimeGenerated\r\n| summarize TotalMemoryConsumedMb = sum(ConsumedValue)/60/1024/1024 by bin(TimeGenerated, 1h), Namespace\r\n| render timechart'
  }
]

resource savedSearch 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = [for item in savedSearches: {
  name: '${workspaceName}/${guid(resourceGroup().id, workspaceName, item.name)}'
  properties: {
    category: item.category
    displayName: item.displayName
    query: item.query
    version: 2
    tags: (contains(item, 'tags') ? item.tags : json('[]'))
  }
}]
