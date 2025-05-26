output "firewall_subnet_id" {
  value = azurerm_subnet.firewall_subnet.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion_subnet.id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway_subnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.hub_vnet.name
}
output "vnet_id" {
  value = azurerm_virtual_network.hub_vnet.id
}