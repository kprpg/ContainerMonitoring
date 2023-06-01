[[_TOC_]]

# Introduction
This demo scenario showcase below monitoring capabilities
- Showcase the difference between monitored and non-monitored Azure kubernetes cluster
- Health monitoring of AKS cluster including both container insights and managed Prometheus.
- Publishing metrics from Prometheus workspace to Azure managed Grafana

# Azure Monitor for Containers
This solution has been used to create an AKS monitoring scenario in the contoso demo environment, and can also be used by users to create replica in their own azure environment.

# Implementation of Managed Prometheus
This solution has also been used for Implementation of Managed Prometheus By Seclecting a appropriate flag " PrometheusDeployment" we can deploy Azure managed prometheus for the same scenario which is powerful tool that enables you to monitor and manage your applications and infrastructure more effectively, providing you with real-time insights and helping you quickly identify and resolve issues and also visualize data using Grafana dashboards.


# Repository Structure

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

# Prerequisites

* Owner/Contributor with User access administrator permission to an azure subscription
* Contributor permission on Azure DevOps project
* Object id from enterprise application is required in azure environment
    - How to retrieve service principal object id 

    ![steps to get object ID](./deploymentStepGIFs/stepsToGetObjectID.gif =1000x)

* Create a new or use existing Managed garafana instance , We are currently using existing Azure managed grafana for the scenario 
Repo Link - https://contosohotelsdev.visualstudio.com/ContosoHotels/_git/ContainerMonitoring?path=%2F&version=GBmain&_a=contents 

# Contribution Workflow

Here’s how it generally works:
- Fork the project.
- Create a topic branch from master.
- Make some commits to improve the project.
- Push this branch to your forked repo.
- Open a Pull Request on project.
- Discuss, and optionally continue committing.
- The project owner merges or closes the Pull Request.
- Sync the updated master back to your fork.

# How to contribute

- [Fork](https://learn.microsoft.com/en-us/azure/devops/repos/git/forks?view=azure-devops&tabs=visual-studio) the repository [ContainerMonitoring](https://contosohotelsdev.visualstudio.com/ContosoHotels/_git/ContainerMonitoring) to [forks](https://contosohotelsdev.visualstudio.com/Forks) Azure DevOps project.

- How to fork a repository

    ![steps to fork container monitoring repository in your Azure DevOps project](./deploymentStepGIFs/stepsToForkRepo.gif =1000x)

- Create a new branch in your forked repository to make your changes.

![gif to create a branch](./deploymentStepGIFs/wiki_create_Branch.gif =1000x)

- Commit the changes and publish the branch. Raise a pull request

![gif to create a branch](./deploymentStepGIFs/wiki_create_PR.gif =1000x)

Project owners will review the pull request and action accordingly.

# How to create pipeline in user environment
- [Clone](https://learn.microsoft.com/en-us/azure/devops/repos/git/clone?view=azure-devops&tabs=visual-studio-2022) the repository [ContainerMonitoring](https://contosohotelsdev.visualstudio.com/ContosoHotels/_git/ContainerMonitoring) to your Azure DevOps project.

- Create or use existing [service principal](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal)

- Use an existing or create a new service connection for azure subscription authentication with devops. 

    ![steps to create new service connection](./deploymentStepGIFs/stepsToCreateServiceConnection.gif =1000x)

- Update service connection in _Container-monitoring-environment.variables.yml_.

    ![Steps to update service connection in variable file](./deploymentStepGIFs/updateSPNInVariableFile.gif =1000x)

- Create a new azure devops build pipeline in your project with existing yaml file within cloned/fork repo.

    ![steps to create pipeline](./deploymentStepGIFs/stepsToCreatePipeline.gif =1000x)


- Enter below variables as pipeline secret variables

    - **ContosoSH360ClusterSPObjectId** - Object id from enterprise application
    - **chVmAdminPassword** - Windows profile user password
    - **chVmAdminUser** - Windows profile username

    ![steps to add pipeline variables](./deploymentStepGIFs/stepsToAddPipelineVariables.gif =1000x)

- **Optional:** Update variables in Container-monitoring-environment.variables.yml variables file to match your environment naming convention

# Pipeline execution

1.  Run the pipeline and enter prefix based on your environment naming convention

    ![steps to run pipeline](./deploymentStepGIFs/stepsToRunPipeline.gif =1000x)

2. Parameter Selection

    * **AKS Cluster Version** - Use supported version for your region

        To find out what versions are currently available for your subscription and region, please refer [AKS cluster supported versions](https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-powershell#azure-portal-and-cli-versions).

