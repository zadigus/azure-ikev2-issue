output "resources_snet_id" {
  value = azurerm_subnet.resources.id
}

output "hub_gw_snet_id" {
  value = azurerm_subnet.gw.id
}

output "inbound_dns_snet_id" {
  value = azurerm_subnet.inbound_dns.id
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.vnet_hub.id
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.vnet_hub.name
}