resource "azurerm_network_security_group" "private_subnet_nsg" {
  name                = "private_network_security_group"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}