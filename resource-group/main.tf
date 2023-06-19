resource "azurerm_resource_group" "rg" {
  name      = local.resource_group_name
  location  = var.location
  tags      = var.resource_group_tags
}