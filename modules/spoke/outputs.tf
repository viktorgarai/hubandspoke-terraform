output "vnet_id" {
  value = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  value = azurerm_virtual_network.spoke.name
}

output "workloads_subnet_id" {
  value = azurerm_subnet.workloads.id
}

output "route_table_id" {
  value = azurerm_route_table.spoke_rt.id
}