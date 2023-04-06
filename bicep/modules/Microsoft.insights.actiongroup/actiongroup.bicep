param PrometheusactionGroup string 
param groupShortName string 
param Receiveremailactiongroups string 

resource actionGroups_prometheus 'microsoft.insights/actionGroups@2023-01-01' = {
  name: PrometheusactionGroup
  location: 'Global'
  properties: {
    groupShortName: groupShortName
    enabled: true
    emailReceivers: [
      {
        name: 'Email_-EmailAction-'
        emailAddress: Receiveremailactiongroups
        useCommonAlertSchema: true
      }
    ]
  }
}
