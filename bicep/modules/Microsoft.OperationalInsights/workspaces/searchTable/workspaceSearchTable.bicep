param location string
param utcValue string = utcNow()
param managedIdentityName string
param roleId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'  //contributor role

param resourceGroupName string
param workspaceName string
param searchTableName string
param searchStartTime string = '2022-10-29T00:00:00Z'
param searchEndTime string = '2022-10-31T00:00:00Z'

// create an user assigned managed identity
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

// assign contributor role to user assiged managed identity
resource roleassignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, roleId, managedIdentityName)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId)
    principalType: 'ServicePrincipal'
  }
}

// create log table based on search job
resource createSearchJobTable 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: searchTableName
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    forceUpdateTag: utcValue
    azPowerShellVersion: '8.0'
    timeout: 'PT10M'
    arguments: '-resourceGroupName ${resourceGroupName} -workspaceName ${workspaceName} -searchTableName ${searchTableName} -searchStartTime ${searchStartTime} -searchEndTime ${searchEndTime}'
    scriptContent: '''
    param( 
      [string] $resourceGroupName,
      [string] $workspaceName,
      [string] $searchTableName,
      [string] $searchStartTime,
      [string] $searchEndTime
    )
    
    $subscriptionId = ((Get-Azcontext).Subscription).id
    $token = (Get-AzAccessToken).Token
    $headers = @{
    Authorization = "Bearer $token"
    'Content-Type' = 'application/json'
    }
    
    $tableUri = "https://management.azure.com/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/tables/$searchTableName" + "?api-version=2021-12-01-preview"
    Write-Host "URI: $($tableUri)"

    $reqbody = "{
    ""properties"": { 
    ""searchResults"": {
          ""query"": ""ContainerLog"",
          ""limit"": 1000,
          ""startSearchTime"": ""$searchStartTime"",
          ""endSearchTime"": ""$searchEndTime""
        }
      }
    }"
    
    Invoke-WebRequest -Method PUT -Uri $tableUri -Headers $headers -ContentType 'application/json' -Body $reqBody -UseBasicParsing
    
    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs["resultStatus"] = $output
    '''

    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    roleassignment
  ]
}
