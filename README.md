# Azure Hub-Spoke Network Terraform Deployment

This project provisions a secure and scalable **Azure Hub-Spoke network topology** using Terraform. It includes a hub virtual network, two spoke networks, shared services (firewall, VPN, bastion), and Windows Server VMs in each spoke.  
**This deployment is ideal for testing and for experimenting with various Azure networking and security scenarios.**  
It is designed for TESTING environments and integrates with Azure DevOps CI/CD, supporting secure secret management via Azure Key Vault.

> ** I Also have a test web application which you can integrate with an SQL database, you can run the application on WebApps, Windows/Linux VMs and do various testing scenarios in Azure
> Link to the App: https://github.com/viktorgarai/TestWebApp **

---

## Features

- **Testing-ready**: Set up according to best practices, the hub and spoke network creates in 10 minutes and is ready to test
- **Ideal for scenario testing**: Quickly validate Azure networking, security, and connectivity patterns
- **Hub-Spoke VNet Architecture** (modular)
- **Centralized Firewall, VPN Gateway, and Bastion Host**
- **Two Spoke VNets** with subnets, route tables, and NSGs
- **Windows Server 2022 VMs** deployed in each spoke
- **Peering** between hub and spokes with optional gateway transit
- **Secure admin credentials** via Azure Key Vault and DevOps variable groups
- **Remote state** management via Azure Storage Account

---

## Azure Network Topology 

                                +-----------------------------------+
                                |             HUB VNET              |
                                |            (10.0.0.0/16)          |
                                |                                   |
                                |  +-----------------------------+  |
                                |  |  Azure Firewall             |  |
                                |  |  (AzureFirewallSubnet)      |  |
                                |  +-----------------------------+  |
                                |                                   |
                                |  +-----------------------------+  |
                                |  |  Bastion Host               |  |
                                |  |  (AzureBastionSubnet)       |  |
                                |  +-----------------------------+  |
                                |                                   |
                                |  +-----------------------------+  |
                                |  |  VPN Gateway                |  |
                                |  |  (GatewaySubnet)            |  |
                                |  +-----------------------------+  |
                                +-----------------+-----------------+
                                                  |
                        +-------------------------+-------------------------+
                        |                                                   |
                +-------v-------+                                   +-------v-------+
                |   Spoke 1     |                                   |   Spoke 2     |
                |   VNet        |                                   |   VNet        |
                | (10.1.0.0/16) |                                   | (10.2.0.0/16) |
                +-------+-------+                                   +-------+-------+
                        |                                                   |
                +-------v-------+                                   +-------v-------+
                | Workloads     |                                   | Workloads     |
                | Subnet  + NSG |                                   | Subnet + NSG  |
                | (10.1.1.0/24) |                                   | (10.2.1.0/24) |
                +-------+-------+                                   +-------+-------+
                        |                                                   |
                +-------v-------+                                   +-------v-------+
                | Windows VM    |                                   | Windows VM    |
                +---------------+                                   +---------------+

### Topology Details

- **Hub VNet (10.0.0.0/16):**
  - Contains:
    - **Azure Firewall** (AzureFirewallSubnet)
    - **Bastion Host** (AzureBastionSubnet)
    - **VPN Gateway** (GatewaySubnet)
- **Spoke VNets:**
  - **Spoke 1 (10.1.0.0/16):** Workloads subnet (10.1.1.0/24) with a Windows VM.
  - **Spoke 2 (10.2.0.0/16):** Workloads subnet (10.2.1.0/24) with a Windows VM.
- **Peering:**
  - Each spoke is peered with the hub, using gateway transit and traffic forwarding.
  - All spoke-to-spoke and internet-bound traffic is routed through the hub firewall.
- **Security:**
  - NSGs protect workloads subnets.
  - Bastion Host provides secure access to VMs without public IPs.

## Terraform directory structure

```
hub-spoke-azure/
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── modules/
│   ├── hub/
│   ├── spoke/
│   ├── firewall/
│   ├── bastion/
│   ├── vpn/
│   └── vm/
├── azure-pipelines.yml
├── azure-pipelines-destroy.yml
└── README.md
```

---

## Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.6.6
- Azure subscription with sufficient permissions
- Azure DevOps project (for CI/CD)
- Azure Key Vault with secrets for VM admin credentials
- Azure Storage Account and container for remote state

---

## Usage

### 1. **Clone the Repository**

```sh
git clone https://github.com/your-org/hub-spoke-azure.git
cd hub-spoke-azure/environments/dev
```

### 2. **Configure Backend and Variables**

- Set up your remote backend (Azure Storage Account).
- Edit `variables.tf` or use a `terraform.tfvars` file for environment-specific values.

## Configure remote state storage account

$RESOURCE_GROUP_NAME='tfstate'
$STORAGE_ACCOUNT_NAME="tfstate$(Get-Random)"
$CONTAINER_NAME='tfstate'

#### Create resource group
New-AzResourceGroup -Name $RESOURCE_GROUP_NAME -Location westeurope

#### Create storage account
$storageAccount = New-AzStorageAccount -ResourceGroupName $RESOURCE_GROUP_NAME -Name $STORAGE_ACCOUNT_NAME -SkuName Standard_LRS -Location westeurope -AllowBlobPublicAccess $false

#### Create blob container
New-AzStorageContainer -Name $CONTAINER_NAME -Context $storageAccount.context

### 3. **Azure DevOps Pipeline Setup**

- Create a variable group in Azure DevOps and link it to your Key Vault secrets:
  - `vm_admin_username`
  - `vm_admin_password`
- Reference the variable group in your pipeline YAML.
- Configure the backend variables as pipeline variables or in a variable group.

### 4. **Deploy**

#### Local (for testing):

```sh
terraform init
terraform plan
terraform apply
```

#### CI/CD (recommended):

- Push changes to your repository.
- The Azure DevOps pipeline (`azure-pipelines.yml`) will:
  - Install Terraform
  - Run `terraform init`, `validate`, `plan`, and `apply`
  - Use secrets from Key Vault for VM credentials

---

## Variables

See [`environments/dev/variables.tf`](environments/dev/variables.tf) for all variables.

Key variables:

| Name                | Description                       | Example/Default      |
|---------------------|-----------------------------------|----------------------|
| location            | Azure region                      | westeurope           |
| resource_group_name | Resource group name               | rg-hub-spoke         |
| vm_admin_username   | VM admin username (from Key Vault)| (secret)             |
| vm_admin_password   | VM admin password (from Key Vault)| (secret)             |

---

## Security & Best Practices

- **Secrets** are not stored in the code; use Azure Key Vault and DevOps variable groups.
- **NSG rules**: Adjust for your use case.
- **Tagging**: I skipped tagging for now, however it's a best practise to add them.
- **Remote state**: Use remote backend for team environments.

---

## Clean Up

To destroy all resources:

```sh
terraform destroy
```

Or via Azure DevOps pipeline azure-pipelines-destroy.yml

---

## Authors

- Viktor Garai

---

## References

- [Azure Hub-Spoke Reference Architecture](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
