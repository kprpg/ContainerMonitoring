# Introduction
This project is dedicated to deliver monitoring capability of container insights for Azure kubernetes service (AKS). This helps team in identifying any issue within their cluster and performing root cause analysis.

# Azure Monitor for Containers
This solution help team in recreating this monitoring scenario within their environment.

## Contents

| File/folder                                      | Description                                |
|--------------------------------------------------|--------------------------------------------|
| `arm`                                            | ARM templates                             |
| `yaml`                                           | Kubernetes configuration files            |
| `.gitignore`                                     | Define what to ignore at commit time      |
| `CHANGELOG.md`                                   | List of changes                           |
| `CONTRIBUTING.md`                                | Guidelines for contributing               |
| `container-monitoring-pipeline.yml`              | Pipeline                             |
| `container-monitoring-environment.variables.yml` | Environment specific variables            |
| `container-monitoring-variables.yml`             | Pipeline variables                        |
| `LICENSE`                                        | License file                         |
| `README.md`                                      | Readme file                        |

## Prerequisites

* Owner access to an azure subscription
* Azure DevOps project
* Permissions to create repositories, import and run pipelines

## Setup

1. Clone/Fork the repository to your Azure DevOps project

    ![steps to fork container monitoring repository in your Azure DevOps project](./deploymentStepGIFs/stepsToForkRepo.gif)

2. Create a service connection as part of azure authentication from pipeline
3. Ensure that the Owner role is assigned to the service connection's service principal. This is required for role assignment within resource provisioning
4. Create a service principal for the Kubernetes cluster
```
Use Get-AzADServicePrincipal to get ObjectId

        (Get-AzADServicePrincipal -DisplayName '<Service Principal Name>').Id
```
5. Create a new pipeline in your project with existing Azure pipelines yaml file.

    ![steps to create pipeline](./deploymentStepGIFs/stepsToCreatePipeline.gif)

6. Create variable group and enter below variables as pipeline secret variables

    - ContosoSH360ClusterSPClientId - This contains client id which will be used in service profile
    - ContosoSH360ClusterSPObjectId - This contain object id of above client id
    - ContosoSH360ClusterSPClientSecret  - This contain client secret for above id
    - chVmAdminPassword - This include windows profile password
    - chVmAdminUser - This include windows profile username

    ![steps to add variable group](./deploymentStepGIFs/stepsToCreateVariableGroup.gif)

7. Update variables in Container-monitoring-environment.variables.yml variables file to match your environment naming convention
8. Update the container-monitoring-pipeline.yml pipeline to use your environment variables file
9. Container-monitoring-pipeline.yml pipeline to your Azure DevOps project

## Runnning the sample

1.  Run the pipeline

    ![steps to run pipeline](./deploymentStepGIFs/stepsToRunPipeline.gif)

## Contributing

It is detailed under ["contributions.md"](https://dev.azure.com/vsogd/_git/DOJO-Whitebelt-SKU?path=%2FCONTRIBUTING.md) file which is present along with source code in the repository.