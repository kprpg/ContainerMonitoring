# Introduction
This project provides the below monitoring capabilities
- Showcase the difference between monitored and non-monitored cluster
- Container insight to monitor AKS cluster resources and health monitoring
- Finding and troubleshooting the root cause for application slowness and failure

# Azure Monitor for Containers
This solution has been used to create an AKS monitoring scenario in the Contoso demo environment, and can also be used to deploy the same replica for users on their own azure environment

## Contents

| File/folder                                      | Description                                |
|--------------------------------------------------|--------------------------------------------|
| `arm`                                            | ARM templates                             |
| `bicep`                                            | Bicep templates                             |
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

* Contributor access to an azure subscription
* Azure DevOps project
* Permissions to create repositories, import and run pipelines
* ContosoSH360ClusterSPClientId - This contains client id which will be used in service profile
* ContosoSH360ClusterSPObjectId - This contain object id of above client id
* ContosoSH360ClusterSPClientSecret  - This contain client secret for above id
* chVmAdminPassword - This include windows profile password
* chVmAdminUser - This include windows profile username

## Setup

1. Clone/Fork the repository to your Azure DevOps project

    ![steps to fork container monitoring repository in your Azure DevOps project](./deploymentStepGIFs/stepsToForkRepo.gif)

    ![steps to clone container monitoring repository](./deploymentStepGIFs/stepsTocloneRepo.gif)

2. Use an existing or create a new service connection as part of azure authentication from pipeline. 

    ![steps to create new service connection](./deploymentStepGIFs/stepsToCreateServiceConnection.gif)

3. Update service connection in Container-monitoring-environment.variables.yml.
    ![Steps to update service connection in variable file](./deploymentStepGIFs/updateSPNInVariableFile.gif)

1. Ensure that the Owner role is assigned to the service connection's service principal. This is required for role assignment within resource provisioning
1. Create a service principal for the Kubernetes cluster
1. Create a new pipeline in your project with existing Azure pipelines yaml file.

    ![steps to create pipeline](./deploymentStepGIFs/stepsToCreatePipeline.gif)

6. Enter below variables as pipeline secret variables

    - ContosoSH360ClusterSPClientId
    - ContosoSH360ClusterSPObjectId
    - ContosoSH360ClusterSPClientSecret
    - chVmAdminPassword
    - chVmAdminUser

    ![steps to add pipeline variables](./deploymentStepGIFs/stepsToAddPipelineVariables.gif)

7. Update variables in Container-monitoring-environment.variables.yml variables file to match your environment naming convention
8. Update the container-monitoring-bicep-pipeline.yml pipeline to use your environment variables file
9. Container-monitoring-bicep-pipeline.yml pipeline to your Azure DevOps project

## Runnning the sample

1.  Run the pipeline

    ![steps to run pipeline](./deploymentStepGIFs/stepsToRunPipeline.gif)

## Contributing

It is detailed under ["contributions.md"]() file which is present along with source code in the repository.