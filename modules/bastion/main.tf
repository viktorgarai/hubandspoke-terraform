resource "azurerm_bastion_host" "bastion" {
  name                = "hub-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}
