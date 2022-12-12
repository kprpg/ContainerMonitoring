param location string
param utcValue string = utcNow()
param managedIdentityName string

param resourceGroupName string
param workspaceName string
param searchTableName string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
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
    arguments: '-resourceGroupName ${resourceGroupName} -workspaceName ${workspaceName} -searchTableName ${searchTableName}'
    scriptContent: '''
    param( 
      [string] $resourceGroupName,
      [string] $workspaceName,
      [string] $searchTableName
    )
    
    $searchStartTime = (Get-Date).AddMonths(-1)
    $searchEndTime = Get-Date

    $subscriptionId = ((Get-Azcontext).Subscription).id
    $token = (Get-AzAccessToken).Token
    $headers = @{
    Authorization = "Bearer $token"
    'Content-Type' = 'application/json'
    }

    $TableUri = "https://management.azure.com/subscriptions/$subscriptionId/resourcegroups/$resourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$workspaceName/tables/$searchTableName" + "?api-version=2021-12-01-preview"
    Write-Host "URI: $($TableUri)"

    try
    {
      Invoke-WebRequest -Method GET -Uri $TableUri -Headers $headers -ContentType 'application/json' -UseBasicParsing 
    }
    catch
    {
      if( $_.exception -like "*404*")
      {
        Write-Host "$searchTableName table doesn't exist" -ForegroundColor Yellow
        Write-Host "Creating search job table $searchTableName" -ForegroundColor Yellow

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

      Invoke-WebRequest -Method PUT -Uri $TableUri -Headers $headers -ContentType 'application/json' -Body $reqBody -UseBasicParsing
      
      }
    }
    
    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs["resultStatus"] = $output
    '''

    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}
