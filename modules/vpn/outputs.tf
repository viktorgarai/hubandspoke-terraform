output "vpn_gateway_id" {
  value = azurerm_virtual_network_gateway.vpn_gw.id
}
output "public_ip_id" {
  value = azurerm_public_ip.vpn_pip.id
}