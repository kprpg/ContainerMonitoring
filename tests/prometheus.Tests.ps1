param(   
    [string] $AzureMonitorWorkspaceName,
    [string] $azureMonitorWorkspaceResourceId,
    [string] $resourceGroupName,
    [string] $PrometheusactionGroup,
    [string] $groupShortName,
    [string] $Receiveremailactiongroups,
    [string] $grafanaName,
    [string] $grafanaresourceGroupName
)
Describe "Checking for all resourceGroup validation for Managed prometheus implementation" {
    BeforeAll {
        #region check for Az.Dashboard module
        try {
            if (!(Get-InstalledModule -Name Az.Dashboard  -ErrorAction SilentlyContinue)) {
                Install-Module -Name Az.Dashboard -AllowClobber -Scope CurrentUser -force -Confirm:$false -ErrorAction Stop -SkipPublisherCheck
                Import-Module -Name Az.Dashboard -force
            }
            else {
                Import-Module Az.Dashboard -force
                Write-Information -InformationAction Continue "Dashboard module already installed so, just importing the module."
            }
        }
        catch {
            Write-Output  "Failed to Install Az.Dashboard Module, error:$($_.exception)"
            throw
        }
    }    
    It "Checking for Azure monitore workspace" {
        try {
            $getWorkspace = Get-AzResource -name $AzureMonitorWorkspaceName -ResourceType Microsoft.Monitor/accounts -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to fetch Azure monitore workspace $($AzureMonitorWorkspaceName),Error:$($_.exception)."
        }
        $getWorkspace.Name | Should -Be $AzureMonitorWorkspaceName
        $getWorkspace.ResourceGroupName | should -Be $resourceGroupName
    }  
    It "Checking for Prometheus ActionGroup" {
        try {            
            $getAG = Get-AzActionGroup -Name $PrometheusactionGroup -ResourceGroup $resourceGroupName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to validate Action Group $($PrometheusactionGroup),Error: $($_.exception)"
        }
        $getAG.name | Should -Be $PrometheusactionGroup
		$getAG.GroupShortName | should -Be $groupShortName
        $getAG.EmailReceivers.EmailAddress | should -be $Receiveremailactiongroups
    }   
    It "Check for Grafana Instance" {
        try {
            $GetGrafana = Get-AzGrafana -Name $grafanaName -ResourceGroupName $grafanaresourceGroupName -WarningAction:SilentlyContinue
        }
        catch {
            Write-output "Failed to validate Grafana Instance $($grafanaName), Error: $($_.exception)"
        }
        $GetGrafana.SkuName | should -Be 'Standard'
        $GetGrafana.IdentityType | should -Be 'SystemAssigned' 
		$GetGrafana.name | should -Be $grafanaName
    } 
}