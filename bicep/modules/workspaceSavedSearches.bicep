param workspaceName string
param name string 
param category string
param displayName string
param query string


resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: workspaceName
}

resource savedSearch 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  name: name
  parent: workspace
  //etag: etag // According to API, the variable should be here, but it doesn't work here.
  properties: {
    displayName: displayName
    category: category
    query: query
    version: 2
  }
}
