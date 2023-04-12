## Introduction
This demo scenario showcase below monitoring capabilities
- Showcase the difference between monitored and non-monitored Azure kubernetes cluster
- Health monitoring of AKS cluster including both container insights and managed Prometheus.
- Publishing metrics from Prometheus workspace to Azure managed Grafana

## Azure Monitor for Containers
This solution has been used to create an AKS monitoring scenario in the contoso demo environment, and can also be used by users to create replica in their own azure environment.

## Implementation of Managed Prometheus
This solution has also been used for Implementation of Managed Prometheus By Seclecting a appropriate flag " PrometheusDeployment" we can deploy Azure managed prometheus for the same scenario which is powerful tool that enables you to monitor and manage your applications and infrastructure more effectively, providing you with real-time insights and helping you quickly identify and resolve issues and also visualize data using Grafana dashboards.


## Contents

| File/folder                                      | Description                                |
|--------------------------------------------------|--------------------------------------------|
| `arm`                                            | ARM templates                             |
| `bicep`                                            | Bicep templates                             |
| `kubernetes-manifests`                                           | Kubernetes configuration files            |
| `.gitignore`                                     | Define what to ignore at commit time      |
| `CHANGELOG.md`                                   | List of changes                           |
| `CONTRIBUTING.md`                                | Guidelines for contributing               |
| `container-monitoring-bicep-pipeline.yml`              | Pipeline                             |
| `container-monitoring-environment.variables.yml` | Environment specific variables            |
| `container-monitoring-variables.yml`             | Pipeline variables                        |
| `LICENSE`                                        | License file                         |
| `README.md`                                      | Readme file                        |

## Prerequisites

* Owner/Contributor with User access administrator permission to an azure subscription
* Contributor permission on Azure DevOps project
* Object id from enterprise application is required in azure environment
    - How to retrieve service principal object id 

    ![steps to get object ID](./deploymentStepGIFs/stepsToGetObjectID.gif =1000x)

* Create a new or use existing Managed garafana instance , We are currently using existing Azure managed grafana for the scenario 
Repo Link - https://contosohotelsdev.visualstudio.com/ContosoHotels/_git/ContainerMonitoring?path=%2F&version=GBmain&_a=contents 

## Setup

1. Clone/Fork the repository [ContainerMonitoring](https://contosohotelsdev.visualstudio.com/ContosoHotels/_git/ContainerMonitoring) to your Azure DevOps project.
- How to fork a repository

    ![steps to fork container monitoring repository in your Azure DevOps project](./deploymentStepGIFs/stepsToForkRepo.gif =1000x)

- How to clone a repository

    ![steps to clone container monitoring repository](./deploymentStepGIFs/stepsTocloneRepo.gif =1000x)

2. Use an existing or create a new service connection for azure subscription authentication with devops. 

    ![steps to create new service connection](./deploymentStepGIFs/stepsToCreateServiceConnection.gif =1000x)

3. Update service connection in _Container-monitoring-environment.variables.yml_.

    ![Steps to update service connection in variable file](./deploymentStepGIFs/updateSPNInVariableFile.gif =1000x)


4. Create a new azure devops build pipeline in your project with existing yaml file within cloned/fork repo.

    ![steps to create pipeline](./deploymentStepGIFs/stepsToCreatePipeline.gif =1000x)


5. Enter below variables as pipeline secret variables

    - **ContosoSH360ClusterSPObjectId** - Object id from enterprise application
    - **chVmAdminPassword** - Windows profile user password
    - **chVmAdminUser** - Windows profile username

    ![steps to add pipeline variables](./deploymentStepGIFs/stepsToAddPipelineVariables.gif =1000x)

6. **Optional:** Update variables in Container-monitoring-environment.variables.yml variables file to match your environment naming convention

## Pipeline execution

1.  Run the pipeline and enter prefix based on your environment naming convention

    ![steps to run pipeline](./deploymentStepGIFs/stepsToRunPipeline.gif =1000x)

2. Parameter Selection

    * **AKS Cluster Version** - Use supported version for your region

        To find out what versions are currently available for your subscription and region, please refer [AKS cluster supported versions](https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-powershell#azure-portal-and-cli-versions).
    
## Contributing

It is detailed under [contributing.md](./CONTRIBUTING.md) file which is present along with source code in the repository.

