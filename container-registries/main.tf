resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  depends_on = [azurerm_private_dns_zone.acr]

  name = format(
    "acr_link_to_%s",
    lower(var.hub_vnet_name),
  )
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_container_registry" "acr" {
  name                          = local.container_reg_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  depends_on = [
    azurerm_private_dns_zone.acr,
    azurerm_container_registry.acr
  ]

  name                = "acr-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  tags = var.tags

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  private_service_connection {
    name                           = "acr-privateserviceconnection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
}