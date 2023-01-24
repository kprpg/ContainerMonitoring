param(   
    [string] $contosoSH360ClusterResourceGroupName,
    [string] $montioredClusterName,
    [string] $nonMontioredClusterName ,
    [string] $ContosoSH360ClusterSPObjectId
)

Describe "checking kubernetesService Deployment" {
    BeforeAll {
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
    }
    It "Checking for Cluster role assignment" {
        try {
            $getkubernetes = Get-AzAksCluster -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $nonMontioredClusterName -WarningAction:SilentlyContinue
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
            Import-AzAksCredential -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $montioredClusterName   -force -Confirm:$false 
            $pods = kubectl get pods --namespace minecraft
            for ($i = 1; $i -lt $pods.Length; $i++) {
                $status = $pods[$i].split(" ")[8]
                $status | Should -Be 'CrashLoopBackOff'
            }
        }
        catch {
            Write-Output  "Failed to fetch minrcraft pods for monitored cluster, error:$($_.exception)"
            throw
        }
    }

    It "Checking purchasing-app deployment for monitored AKS cluster" {
        try {
            Import-AzAksCredential -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $montioredClusterName   -force -Confirm:$false 
            $deployment = kubectl get deployments purchasing-app
            $deployment[1].split(" ")[0] | Should -Be 'purchasing-app'
        }
        catch {
            Write-Output  "Failed to fetch purchasing-app deployment for monitored AKS cluster, error:$($_.exception)"
            throw
        }
    }

    It "Checking nginxsvc service for monitored AKS cluster" {
        try {
            Import-AzAksCredential -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $montioredClusterName   -force -Confirm:$false 
            $service = kubectl get service nginxsvc
            $service[1].split(" ")[0] | Should -Be 'nginxsvc'
        }
        catch {
            Write-Output  "Failed to fetch nginxsvc service for monitored AKS cluster, error:$($_.exception)"
            throw
        }
    }

    It "Checking sample deployment for monitored AKS cluster" {
        try {
            Import-AzAksCredential -ResourceGroupName $contosoSH360ClusterResourceGroupName -Name $montioredClusterName   -force -Confirm:$false 
            $deployment = kubectl get deployments sample
            $deployment[1].split(" ")[0] | Should -Be 'sample'
        }
        catch {
            Write-Output  "Failed to fetch sample deployment for monitored AKS cluster, error:$($_.exception)"
            throw
        }
    }
    
}