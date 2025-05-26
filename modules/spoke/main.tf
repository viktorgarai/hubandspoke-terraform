resource "azurerm_virtual_network" "spoke" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags = var.tags
}

resource "azurerm_subnet" "workloads" {
  name                 = "workloads"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = var.workloads_subnet_prefix
}


# Route table for spoke network

resource "azurerm_route_table" "spoke_rt" {
  name                = "${var.name}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = var.tags

  route {
    name           = "default-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "route_assoc" {
  subnet_id      = azurerm_subnet.workloads.id
  route_table_id = azurerm_route_table.spoke_rt.id
}

# NSG for workloads subnet

resource "azurerm_network_security_group" "workloads_nsg" {
  name                = "${var.name}-workloads-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

security_rule {
  name                       = "AllowInbound-HTTPS"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80" 
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
security_rule {
  name                       = "AllowInbound-HTTP"
  priority                   = 130
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443" 
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
security_rule {
  name                       = "AllowInbound-SSH"
  priority                   = 140
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22" 
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
security_rule {
  name                       = "AllowInbound-RDP"
  priority                   = 150
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3389" 
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
security_rule {
  name                       = "AllowInbound-ICMP"
  priority                   = 160
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Icmp"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.workloads.id
  network_security_group_id = azurerm_network_security_group.workloads_nsg.id
}