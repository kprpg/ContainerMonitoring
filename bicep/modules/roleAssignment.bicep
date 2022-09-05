param clusterName string
@description('Client ID (used by cloudprovider)')
@secure()
param ContosoSH360ClusterSPObjectId string
param monitoringMetricsPublisherRoleDefinition string = '3913510d-42f4-4e42-8a64-420c390055eb'

var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricsPublisherRoleDefinition)

resource clusterResource 'Microsoft.ContainerService/managedClusters@2022-01-01' existing = {
  name: clusterName
}
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, ContosoSH360ClusterSPObjectId)
  scope: clusterResource
  properties: {
    principalId: ContosoSH360ClusterSPObjectId
    roleDefinitionId: roleDefinitionId
  }
}
