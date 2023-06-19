resource "azurerm_virtual_network" "vnet_hub" {
  name                = "HubVnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.hub_network["vnet"]]

  tags = var.tags
}

resource "azurerm_subnet" "gw" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = [var.hub_network["vpn_gateway"]]
}

resource "azurerm_subnet" "resources" {
  name                 = "ResourcesSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = [var.hub_network["resources"]]
}

resource "azurerm_subnet_network_security_group_association" "resources" {
  subnet_id                 = azurerm_subnet.resources.id
  network_security_group_id = var.private_subnet_nsg_id
}

resource "azurerm_subnet" "inbound_dns" {
  name                 = "InboundDNS"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = [var.hub_network["inbounddns"]]

  delegation {
    name = "Microsoft.Network.dnsResolvers"

    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "inbound_dns" {
  subnet_id                 = azurerm_subnet.inbound_dns.id
  network_security_group_id = var.private_subnet_nsg_id
}