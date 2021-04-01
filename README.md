---
page_type: Azure Monitor for Containers
languages:
- ARM templates
products:
- kubernetes
description: "monitor an Azure Kubernetes Service (AKS) cluster with Azure Monitor for containers"
urlFragment: "update-this-to-unique-url-stub"
---

# Azure Monitor for Containers

<!-- 
Guidelines on README format: https://review.docs.microsoft.com/help/onboard/admin/samples/concepts/readme-template?branch=master

Guidance on onboarding samples to docs.microsoft.com/samples: https://review.docs.microsoft.com/help/onboard/admin/samples/process/onboarding?branch=master

Taxonomies for products and languages: https://review.docs.microsoft.com/new-hope/information-architecture/metadata/taxonomies?branch=master
-->

This solution deployes resources for the Azure Monitor for containers demo scenario.

## Contents

| File/folder       | Description                                |
|-------------------|--------------------------------------------|
| `arm`             | ARM templates.                        |
| `yaml`            | Kubernetes configuration files.                        |
| `.gitignore`      | Define what to ignore at commit time.      |
| `CHANGELOG.md`    | List of changes to the sample.             |
| `CONTRIBUTING.md` | Guidelines for contributing to the sample. |
| `README.md`       | This README file.                          |
| `LICENSE`         | The license for the sample.                |

## Prerequisites

Outline the required components and tools that a user might need to have on their machine in order to run the sample. This can be anything from frameworks, SDKs, OS versions or IDE releases.

## Setup

Explain how to prepare the sample once the user clones or downloads the repository. The section should outline every step necessary to install dependencies and set up any settings (for example, API keys and output folders).

## Runnning the sample

Outline step-by-step instructions to execute the sample and see its output. Include steps for executing the sample from the IDE, starting specific services in the Azure portal or anything related to the overall launch of the code.

## Key concepts

Provide users with more context on the tools and services used in the sample. Explain some of the code that is being used and how services interact with each other.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.


# Azure Monitor for Containers 
This solution demostrates how to monitor an Azure Kubernetes Service (AKS) cluster with Azure Monitor for containers.

# Getting Started
1.	Clone the repository to your Azure DevOps project
1.	Create a service connection
1.	Ensure that the Contributor role is assigned to the service connection's service principal
1.	If you don't have a key vault, create one
1.  Create a service principal for the Kubernetes cluster
1.  Add service principal's application ID, object ID and secret to the key vault as ContosoSH360ClusterSPClientId, ContosoSH360ClusterSPObjectId and ContosoSH360ClusterSPClientSecret secrets
1.  Copy the container-monitoring-environment.variables.yml variables file and rename it to match your environment
1.  Update the environment variables file with correponding values
1.  Update the container-monitoring-pipeline.yml pipeline to use your environment variables file
1.  Import the container-monitoring-pipeline.yml pipeline to your Azure DevOps project
1.  Run the pipeline
