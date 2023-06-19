resource "azurerm_public_ip" "gw" {
  name                = "hubvnetgwip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "hub_gw" {
  depends_on = [azurerm_public_ip.gw]

  name                = "vnetgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  tags = var.tags

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  vpn_client_configuration {
    address_space        = [var.vpn_client_address_pools]
    vpn_client_protocols = ["IkeV2", "OpenVPN"]
    root_certificate {
      name             = "vpn_root_ca"
      public_cert_data = var.public_root_cert_data
    }
  }
}

resource "azurerm_private_dns_resolver" "hub" {
  name                = "privatednsresolver"
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_network_id  = var.hub_vnet_id
  tags                = var.tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "hub" {
  name                    = "InboundEndpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.hub.id
  location                = var.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = var.inbound_dns_subnet_id
  }
  tags = var.tags
}