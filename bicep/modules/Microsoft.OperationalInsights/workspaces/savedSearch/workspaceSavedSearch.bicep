param workspaceName string

var savedSearches = [
  {
    category: 'Container Insights'
    displayName: 'CPU usage by Namespace'
    query: 'KubePodInventory\n| where isnotempty(Computer)\n// eliminate unscheduled pods\n| where PodStatus in (\'Running\',\'Unknown\')\n| summarize by bin(TimeGenerated, 1m), Computer, ClusterId, ContainerName, Namespace\n| project TimeGenerated, InstanceName = strcat(ClusterId, \'/\', ContainerName), Namespace\n| join\n(\n    Perf\n    | where ObjectName == \'K8SContainer\'\n    | where CounterName == \'cpuUsageNanoCores\'\n    | summarize UsageValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\n    | project-away CounterName\n    | join kind = fullouter\n    (\n        Perf\n        | where ObjectName == \'K8SContainer\'\n        | where CounterName == \'cpuRequestNanoCores\'\n        | summarize RequestValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\n        | project-away CounterName\n    )\n    on Computer, InstanceName, TimeGenerated\n    | project TimeGenerated = iif(isnotempty(TimeGenerated), TimeGenerated, TimeGenerated1),   Computer = iif(isnotempty(Computer), Computer, Computer1),  InstanceName = iif(isnotempty(InstanceName), InstanceName, InstanceName1),  UsageValue = iif(isnotempty(UsageValue), UsageValue, 0.0),   RequestValue = iif(isnotempty(RequestValue), RequestValue, 0.0)\n    | extend ConsumedValue = iif(UsageValue > RequestValue, UsageValue, RequestValue)\n)\non InstanceName, TimeGenerated\n| summarize TotalCpuConsumedCores = sum(ConsumedValue) / 60 / 1000000 by bin(TimeGenerated, 1h), Namespace\n| render piechart'
  }
  {
    category: 'Container Insights'
    displayName: 'Disk RPS per disk per node'
    query: 'InsightsMetrics\n| where Namespace == \'container.azm.ms/diskio\'\n| where TimeGenerated > ago(1h)\n| where Name == \'reads\'\n| extend Tags = todynamic(Tags)\n| extend HostName = tostring(Tags.hostName), Device = Tags.name\n| extend NodeDisk = strcat(Device, "/", HostName)\n| order by NodeDisk asc, TimeGenerated asc\n| serialize\n| extend PrevVal = iif(prev(NodeDisk) != NodeDisk, 0.0, prev(Val)), PrevTimeGenerated = iif(prev(NodeDisk) != NodeDisk, datetime(null), prev(TimeGenerated))\n| where isnotnull(PrevTimeGenerated) and PrevTimeGenerated != TimeGenerated\n| extend Rate = iif(PrevVal > Val, Val / (datetime_diff(\'Second\', TimeGenerated, PrevTimeGenerated) * 1), iif(PrevVal == Val, 0.0, (Val - PrevVal) / (datetime_diff(\'Second\', TimeGenerated, PrevTimeGenerated) * 1)))\n| where isnotnull(Rate)\n| project TimeGenerated, NodeDisk, Rate\n| render timechart'
  }
  {
    category: 'Container Insights'
    displayName: 'KubeEvents Insights by Reason'
    query: 'KubeEvents\n| summarize count() by Message\n| render columnchart'
  }
  {
    category: 'Container Insights'
    displayName: 'Logs contains Failure or Error or Exception'
    query: 'ConainerLogV2\n| where TimeGenerated > ago(30m)\n| where (LogEntry contains "failed" or LogEntry contains "error" or LogEntry contains "exception")\n| project TimeGenerated, LogEntry, ContainerID, Computer'
  }
  {
    category: 'Container Insights'
    displayName: 'Memory usage by Namespace'
    query: '// ********************\n// memory usage\n// ********************\nKubePodInventory\n//| where ClusterName == \'contosoretail2\'\n| where isnotempty(Computer)\n// eliminate unscheduled pods\n| where PodStatus in (\'Running\',\'Unknown\')\n| summarize by bin(TimeGenerated, 1m), Computer, ClusterId, ContainerName, Namespace\n| project TimeGenerated, InstanceName = strcat(ClusterId, \'/\', ContainerName), Namespace\n| join\n(\n    Perf\n    | where ObjectName == \'K8SContainer\'\n    | where CounterName == \'memoryRssBytes\'\n    | summarize UsageValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\n    | project-away CounterName\n    | join kind = fullouter\n    (\n        Perf\n        | where ObjectName == \'K8SContainer\'\n        | where CounterName == \'memoryRequestBytes\'\n        | summarize RequestValue = max(CounterValue) by bin(TimeGenerated, 1m), Computer, InstanceName, CounterName\n        | project-away CounterName\n    )\n    on Computer, InstanceName, TimeGenerated\n    | project TimeGenerated = iif(isnotempty(TimeGenerated), TimeGenerated, TimeGenerated1), Computer = iif(isnotempty(Computer), Computer, Computer1), InstanceName = iif(isnotempty(InstanceName), InstanceName, InstanceName1), UsageValue = iif(isnotempty(UsageValue), UsageValue, 0.0), RequestValue = iif(isnotempty(RequestValue), RequestValue, 0.0)\n    | extend ConsumedValue = iif(UsageValue > RequestValue, UsageValue, RequestValue)\n)\non InstanceName, TimeGenerated\n| summarize TotalMemoryConsumedMb = sum(ConsumedValue)/60/1024/1024 by bin(TimeGenerated, 1h), Namespace\n| render timechart'
  }
]

resource workspaceSavedSearches 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = [for item in savedSearches: {
  name: '${workspaceName}/${guid(resourceGroup().id, workspaceName, (empty(savedSearches) ? '__blank__' : item.category), (empty(savedSearches) ? '__blank__' : item.displayName))}'
  properties: {
    etag: '*'
    category: item.category
    displayName: item.displayName
    query: item.query
    version: 2
    tags: (contains(item, 'tags') ? item.tags : json('[]'))
  }
}]
