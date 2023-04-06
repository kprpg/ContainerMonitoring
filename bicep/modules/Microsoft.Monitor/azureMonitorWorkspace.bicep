
// The below template deploys a Azure monitor workspace for container monitoring scenarios.

param PrometheusworkspaceName string
param location string 

resource workspace 'microsoft.monitor/accounts@2021-06-03-preview' = {
  name: PrometheusworkspaceName
  location: location
}
