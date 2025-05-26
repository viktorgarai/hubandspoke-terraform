terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.30.0"
    }
  }
}

# 2. Configure the AzureRM Provider
provider "azurerm" {
  # The AzureRM Provider supports authenticating using via the Azure CLI, a Managed Identity
  # and a Service Principal. More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure

  # The features block allows changing the behaviour of the Azure Provider, more
  # information can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
  features {}
}

resource "azurerm_resource_group" "rg-hub-spoke" {
  name     = var.resource_group_name
  location = var.location
}

# Hub network and services

module "hub" {
  source              = "../../modules/hub"
  vnet_name           = "hub-vnet"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.rg-hub-spoke.name
  location            = azurerm_resource_group.rg-hub-spoke.location
  tags                = var.tags
}

module "firewall" {
  source              = "../../modules/firewall"
  resource_group_name = azurerm_resource_group.rg-hub-spoke.name
  location            = azurerm_resource_group.rg-hub-spoke.location
  subnet_id           = module.hub.firewall_subnet_id
  tags                = var.tags
}

module "bastion" {
  source              = "../../modules/bastion"
  resource_group_name = azurerm_resource_group.rg-hub-spoke.name
  location            = azurerm_resource_group.rg-hub-spoke.location
  subnet_id           = module.hub.bastion_subnet_id
  tags                = var.tags
}

module "vpn" {
  source              = "../../modules/vpn"
  resource_group_name = azurerm_resource_group.rg-hub-spoke.name
  location            = azurerm_resource_group.rg-hub-spoke.location
  subnet_id           = module.hub.gateway_subnet_id
  tags                = var.tags
}

# Spoke networks

module "spoke1" {
  source                  = "../../modules/spoke"
  name                    = "spoke1-vnet"
  resource_group_name     = azurerm_resource_group.rg-hub-spoke.name
  location                = azurerm_resource_group.rg-hub-spoke.location
  address_space           = ["10.1.0.0/16"]
  workloads_subnet_prefix = ["10.1.1.0/24"]
  firewall_private_ip     = module.firewall.firewall_private_ip
  tags                    = var.tags
}

module "spoke2" {
  source                  = "../../modules/spoke"
  name                    = "spoke2-vnet"
  resource_group_name     = azurerm_resource_group.rg-hub-spoke.name
  location                = azurerm_resource_group.rg-hub-spoke.location
  address_space           = ["10.2.0.0/16"]
  workloads_subnet_prefix = ["10.2.1.0/24"]
  firewall_private_ip     = module.firewall.firewall_private_ip
  tags                    = var.tags
}

#VMs
module "spoke1_vm" {
  source              = "../../modules/vm"
  vm_name             = "spoke1-vm"
  resource_group_name = azurerm_resource_group.rg-hub-spoke.name
  location            = azurerm_resource_group.rg-hub-spoke.location
  subnet_id           = module.spoke1.workloads_subnet_id
  vm_size             = "Standard_B2ms"
  vm_admin_username   = var.vm_admin_username
  vm_admin_password   = var.vm_admin_password
  tags                = var.tags
}

module "spoke2_vm" {
  source              = "../../modules/vm"
  vm_name             = "spoke2-vm"
  resource_group_name = azurerm_resource_group.rg-hub-spoke.name
  location            = azurerm_resource_group.rg-hub-spoke.location
  subnet_id           = module.spoke2.workloads_subnet_id
  vm_size             = "Standard_B2ms"
  vm_admin_username   = var.vm_admin_username
  vm_admin_password   = var.vm_admin_password
  tags                = var.tags
}

# Peering the spoke networks to the hub network
# For spoke1
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                      = "hub-to-spoke1"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = module.hub.vnet_name
  remote_virtual_network_id = module.spoke1.vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                      = "spoke1-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = module.spoke1.vnet_name
  remote_virtual_network_id = module.hub.vnet_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true
  depends_on                = [module.vpn]
}

# For spoke2
resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                      = "hub-to-spoke2"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = module.hub.vnet_name
  remote_virtual_network_id = module.spoke2.vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                      = "spoke2-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = module.spoke2.vnet_name
  remote_virtual_network_id = module.hub.vnet_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true
  depends_on                = [module.vpn]
}
