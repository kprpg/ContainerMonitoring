param(   
    [string] $contosoSH360ClusterResourceGroupName,
    [string] $opsResourceGroupName,
    [string] $logAnalyticsWorkspaceName,
    [string] $monitoredClusterName,
    [string] $nonmonitoredClusterName ,
    [string] $managedIdentityName,
    [string] $searchTableName,
    [string] $kubernetesVersion,
    [string] $workspaceSkuName,
    [string] $agentVMSize,
    [int] $retentionPeriod
)

Describe "Checking for all resourceGroup validation" {
    BeforeAll {
   
        #region check for Az.ManagedServiceIdentity module
        try {
            if (!(Get-InstalledModule -Name Az.ManagedServiceIdentity -RequiredVersion 0.7.3  -ErrorAction SilentlyContinue)) {
                Install-Module -Name Az.ManagedServiceIdentity -RequiredVersion 0.7.3 -AllowClobber -Scope CurrentUser -force -Confirm:$false -ErrorAction Stop -SkipPublisherCheck
                Import-Module -Name Az.ManagedServiceIdentity -force
                $msiAdded = $true
            }
            else {
                Import-Module Az.ManagedServiceIdentity -force
                Write-Information -InformationAction Continue "ManagedServiceIdentity module already installed so, just importing the module."
            }
        }
        catch {
            Write-Output  "Failed to Install Az.ManagedServiceIdentity Module, error:$($_.exception)"
            throw
        }
    }
    It "Checking for contosoSH360ClusterResourceGroup" {
        try {            
            $getRG = Get-AzResourceGroup -Name $contosoSH360ClusterResourceGroupName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to validate resourceGroup $($contosoSH360ClusterResourceGroupName),Error: $($_.exception)"
        }
        $getRG.ResourceGroupName | Should -Be $contosoSH360ClusterResourceGroupName
    }

    It "Checking for opsResourceGroup" {
        try {            
            $getRG = Get-AzResourceGroup -Name $opsResourceGroupName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to validate resourceGroup $($opsResourceGroupName),Error: $($_.exception)"
        }
        $getRG.ResourceGroupName | Should -Be $opsResourceGroupName
    }

    It "Checking for logAnalyticsWorkspace" {
        try {
            $getWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $opsResourceGroupName -Name $logAnalyticsWorkspaceName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to fetch logAnalyticsWorkspace $($logAnalyticsWorkspaceName),Error:$($_.exception)."
        }
        $getWorkspace.Name | Should -Be $logAnalyticsWorkspaceName
        $getWorkspace.retentionInDays | Should -Be $retentionPeriod
        $getWorkspace.Sku | Should -Be $workspaceSkuName
        $getWorkspace.ProvisioningState | Should -Be 'Succeeded'
    }

    It "Checking for logAnalyticsWorkspace saved searches" {
        $savedSearches = @(
            @{
                category    = "Container Insights"
                displayName = "CPU usage by Namespace"
            }
            @{
                category    = "Container Insights"
                displayName = "Disk RPS per disk per node"
            }
            @{
                category    = "Container Insights"
                displayName = "KubeEvents Insights by Reason"
            }
            @{
                category    = "Container Insights"
                displayName = "Logs contains Failure or Error or Exception"
            }
            @{
                category    = "Container Insights"
                displayName = "Memory usage by Namespacek"
            }
        )
        try {
            $getSavedSearch = Get-AzOperationalInsightsSavedSearch -ResourceGroupName $opsResourceGroupName -WorkspaceName $logAnalyticsWorkspaceName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to fetch saved search for logAnalyticsWorkspace $($logAnalyticsWorkspaceName),Error:$($_.exception)."
        }        
        foreach ($savedSearch in $savedSearches) {
            try {
                $result = $getSavedSearch.Value | Where-Object { $_.Properties.DisplayName -eq $savedSearch.displayName -and $_.Properties.Category -eq $savedSearch.category }
                $result.Properties.DisplayName | Should -Be  $savedSearch.displayName
            }
            catch {
                Write-output "Failed to fetch  saved Search $($savedSearch),Error:$($_.exception)."
            }
        }
    }

    It "Checking for logAnalyticsWorkspace search table" {
        try {
            $getSearchTable = Get-AzOperationalInsightsTable -ResourceGroupName $opsResourceGroupName -WorkspaceName $logAnalyticsWorkspaceName -tableName "ContainerLogV2" -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to fetch logAnalyticsWorkspace search Table ContainerLogV2 for $($workspaceName),Error:$($_.exception)."
        }
        $getSearchTable.Name | Should -Be 'ContainerLogV2'
        $getSearchTable.RetentionInDays | Should -Be 8
    }

    It "Checking for logAnalyticsWorkspace Search Job Table" {
        try {
            $getJobTable = Get-AzOperationalInsightsTable -ResourceGroupName $opsResourceGroupName -WorkspaceName $logAnalyticsWorkspaceName -tableName $searchTableName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to fetch logAnalyticsWorkspace searchJobTable $($searchTableName),Error:$($_.exception)."
        }
        $getJobTable.Name | Should -Be $searchTableName
    }
    
    It "Checking for user assigned managed identity" {
        try {
            $getManagedIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $opsResourceGroupName -Name  $managedIdentityName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to fetch managed identity $($managedIdentityName),Error:$($_.exception)."
        }
        $getManagedIdentity.Name | Should -Be $managedIdentityName
    }

    It "Checking for monitored AKS cluster deployment" {
        try {
            $getkubernetes = Get-AzAksCluster -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $monitoredClusterName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to fetch  AKS cluster $($monitoredClusterName),Error:$($_.exception)."
        }
        $getkubernetes.Name | Should -Be $monitoredClusterName
        $getkubernetes.KubernetesVersion | Should -Be $kubernetesVersion
        $getkubernetes.ProvisioningState | Should -Be 'Succeeded'
        $getkubernetes.EnableRBAC | Should -Be $true
        $getkubernetes.AgentPoolProfiles.Count | Should -Be 2
    }

    It "Checking for monitored pool node linuxpool for AKS cluster deployment" {
        try {
            $getNode = (Get-AzAksCluster -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $monitoredClusterName -WarningAction:SilentlyContinue).AgentPoolProfiles | Where-Object -Property Name -eq 'linuxpool'
        }
        catch {
            Write-output "Failed to fetch  AKS cluster node linuxpool  $($monitoredClusterName),Error:$($_.exception)."
        }
        $getNode.Name | Should -Be 'linuxpool'
        $getNode.Count | Should -Be 2
        $getNode.OsDiskSizeGB | Should -Be 120
        $getNode.OsType | Should -Be 'Linux'
        $getNode.Mode | Should -Be 'System'
        $getNode.MaxCount | Should -Be 2
        $getNode.MinCount | Should -Be 2
        $getNode.Type | Should -Be 'VirtualMachineScaleSets'
        $getNode.EnableAutoScaling  | Should -Be $true
        $getNode.ProvisioningState | Should -Be 'Succeeded'
        $getNode.VmSize | Should -Be $agentVMSize
    }

    It "Checking for monitored pool node window for AKS cluster deployment" {
        try {
            $getNode = (Get-AzAksCluster -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $monitoredClusterName -WarningAction:SilentlyContinue).AgentPoolProfiles | Where-Object -Property Name -eq 'window'
        }
        catch {
            Write-output "Failed to fetch  AKS cluster node window for $($monitoredClusterName),Error:$($_.exception)."
        }
        $getNode.Name | Should -Be 'window'
        $getNode.Count | Should -Be 1
        $getNode.OsDiskSizeGB | Should -Be 120
        $getNode.OsType | Should -Be 'Windows'
        $getNode.MaxCount | Should -Be 1
        $getNode.MinCount | Should -Be 1
        $getNode.Type | Should -Be 'VirtualMachineScaleSets'
        $getNode.EnableAutoScaling  | Should -Be $true
        $getNode.ProvisioningState | Should -Be 'Succeeded'
        $getNode.VmSize | Should -Be $agentVMSize
    }

    It "Checking for nonMonitored AKS cluster deployment" {
        try {
            $getkubernetes = Get-AzAksCluster -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $nonmonitoredClusterName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to fetch  AKS cluster $($nonmonitoredClusterName),Error:$($_.exception)."
        }
        $getkubernetes.Name | Should -Be $nonmonitoredClusterName
        $getkubernetes.KubernetesVersion | Should -Be $kubernetesVersion
        $getkubernetes.ProvisioningState | Should -Be 'Succeeded'
        $getkubernetes.EnableRBAC | Should -Be $true
        $getkubernetes.AgentPoolProfiles.Count | Should -Be 1
    }

    It "Checking for nonMonitored pool node linuxpool for AKS cluster deployment" {
        try {
            $getNode = (Get-AzAksCluster -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $nonmonitoredClusterName  -WarningAction:SilentlyContinue).AgentPoolProfiles | Where-Object -Property Name -eq 'linuxpool'
        }
        catch {
            Write-output "Failed to fetch  AKS cluster node linuxpool  $($nonmonitoredClusterName),Error:$($_.exception)."
        }
        $getNode.Name | Should -Be 'linuxpool'
        $getNode.OsDiskSizeGB | Should -Be 120
        $getNode.OsType | Should -Be 'Linux'
        $getNode.Mode | Should -Be 'System'
        $getNode.MaxCount | Should -Be 3
        $getNode.MinCount | Should -Be 2
        $getNode.Type | Should -Be 'VirtualMachineScaleSets'
        $getNode.ProvisioningState | Should -Be 'Succeeded'
        $getNode.VmSize | Should -Be $agentVMSize
    }

    AfterAll {
        #Unloading Unloading ManagedServiceIdentity Module Modules
        try {
            if ($msiAdded -eq $true) {
                Write-Information -InformationAction Continue -MessageData "Unloading ManagedServiceIdentity Module."
                Remove-Module Az.ManagedServiceIdentity -Confirm:$false -Force -WarningAction:SilentlyContinue -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Information -InformationAction Continue -MessageData  "Failed to Unload ManagedServiceIdentity Module"
            throw $_.exception
        }
    }
}