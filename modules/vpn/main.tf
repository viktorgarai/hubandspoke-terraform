resource "azurerm_virtual_network_gateway" "vpn_gw" {
  name                = "hub-vpn"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "Basic"
  tags = var.tags

  ip_configuration {
    name                          = "vpnconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_pip.id
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "vpn_pip" {
  name                = "vpn-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags = var.tags
}
