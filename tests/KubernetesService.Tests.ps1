param(   
    [string] $contosoSH360ClusterResourceGroupName,
    [string] $monitoredClusterName
    #[string] $ContosoSH360ClusterSPObjectId
)

BeforeAll {

    #region check for az.aks module
    try {
        if (!(Get-InstalledModule -Name az.aks -RequiredVersion 4.2.1 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)) {
            Install-Module -Name az.aks -RequiredVersion 4.2.1 -AllowClobber -force
            Import-Module -Name az.aks -RequiredVersion 4.2.1 -force
            $aksInstalled = $true
        }
        else {
            Write-Information -InformationAction Continue -MessageData "aks module already installed so, just importing the module."
            Import-Module -Name az.aks -force
        }
    }
    catch {
        Write-Information -InformationAction Continue -MessageData  "Failed to Install Az.aks Module, error:$($_.exception)"
        throw
    }

    #installing the AzAksKubectl module.
    try {
        Install-AzAksKubectl -Version latest -force -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Output  "Failed to Install Az.AzAksKubectl Module, error:$($_.exception)"
        throw
    }
    #Adding AzAksKubectl module path to env:path
    try {
        $AzAksKubectlPath = $HOME + "\.azure-kubectl;"
        $env:Path = $env:Path + $AzAksKubectlPath
        Write-Output $env:Path
    }
    catch {
        Write-Output  "Failed to add path of Az.AzAksKubectl Module to system environement, error:$($_.exception)"
        throw
    }

    Import-AzAksCredential -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $monitoredClusterName -force -Confirm:$false 


}
Describe "checking kubernetesService Deployment" {
    It "Checking for Cluster role assignment" {
        try {
            $getkubernetes = Get-AzAksCluster -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $monitoredClusterName -WarningAction:SilentlyContinue
            $getRoleAssignment = Get-AzRoleAssignment -Scope $getkubernetes.Id -ObjectId $ContosoSH360ClusterSPObjectId -RoleDefinitionName 'Monitoring Metrics Publisher'
        }
        catch {
            Write-Output  "Failed to fetch role assignment, error:$($_.exception)"
            throw
        }
        $getRoleAssignment.RoleDefinitionName | Should -Be 'Monitoring Metrics Publisher'
    }

    It "Checking minecraft pods for monitored AKS cluster" {
        try {
            $pods = (kubectl get pods --namespace minecraft -o json) | ConvertFrom-Json 
        }
        catch {
            Write-Output  "Failed to fetch minrcraft pods for monitored cluster, error:$($_.exception)"
            throw
        }
        $pods.items.Count | Should -Be 4
        foreach ($pod in $pods.items) {
            $pod.status.containerStatuses.state.waiting.reason | Should -Be 'CrashLoopBackOff'
            $pod.status.phase | Should -Be 'running'
        }
    }

    It "Checking default pods for monitored AKS cluster" {
        try {
            $pods = (kubectl get pods --namespace default -o json) | ConvertFrom-Json 
        }
        catch {
            Write-Output  "Failed to fetch default pods for monitored cluster, error:$($_.exception)"
            throw
        }
        $pods.items.Count | Should -Be 4
    }

    It "Checking purchasing-app deployment for monitored AKS cluster" {
        try {
            Import-AzAksCredential -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $monitoredClusterName   -force -Confirm:$false 
            $deployment = kubectl get deployments purchasing-app -o json | ConvertFrom-Json
        }
        catch {
            Write-Output  "Failed to fetch purchasing-app deployment for monitored AKS cluster, error:$($_.exception)"
            throw
        }
        $deployment.kind | Should -Be 'Deployment'
        $deployment.metadata.name | Should -Be 'purchasing-app'
        $deployment.metadata.namespace | Should -Be 'default'
    }

    It "Checking nginxsvc service for monitored AKS cluster" {
        try {
            Import-AzAksCredential -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $monitoredClusterName   -force -Confirm:$false 
            $service = kubectl get service nginxsvc -o json | ConvertFrom-Json
        }
        catch {
            Write-Output  "Failed to fetch nginxsvc service for monitored AKS cluster, error:$($_.exception)"
            throw
        }
        $service.kind | Should -Be 'Service'
        $service.metadata.name | Should -Be 'nginxsvc'
        $service.metadata.namespace | Should -Be 'default'

    }

    It "Checking sample deployment for monitored AKS cluster" {
        try {
            Import-AzAksCredential -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $monitoredClusterName   -force -Confirm:$false 
            $deployment = kubectl get deployments sample -o json | ConvertFrom-Json
        }
        catch {
            Write-Output  "Failed to fetch sample deployment for monitored AKS cluster, error:$($_.exception)"
            throw
        }
        $deployment.kind | Should -Be 'Deployment'
        $deployment.metadata.name | Should -Be 'sample'
        $deployment.metadata.namespace | Should -Be 'default'
    }
    
}

AfterAll {
    ##Unloading aks Module##
    try {
        if ($aksInstalled -eq $true) {
            Write-Information -InformationAction Continue -MessageData  "Unloading aks Module."
            Remove-Module az.aks -Confirm:$false -Force -WarningAction:SilentlyContinue -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Information -InformationAction Continue -MessageData  "Failed to Unload aks Module"
        throw $_.exception
    }
}