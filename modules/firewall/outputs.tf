output "firewall_id" {
  value = azurerm_firewall.hub_fw.id
}
output "firewall_private_ip" {
  value = azurerm_firewall.hub_fw.ip_configuration[0].private_ip_address
}
output "public_ip_id" {
  value = azurerm_public_ip.fw_pip.id
}