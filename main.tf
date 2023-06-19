module "resource_group" {
  source              = "./resource-group"
  group_prefix        = replace(join("-", [var.project_name, var.jira_project_id]), "/", "")
  location            = var.location
  resource_group_tags = merge(local.tags, var.resource_group_tags)
}

module "nsg" {
  depends_on = [module.resource_group]
  source     = "./nsg"

  name_prefix         = local.resource_prefix
  name_suffix         = local.resource_suffix
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

module "vnets" {
  depends_on = [module.resource_group, module.nsg]
  source     = "./vnet"

  location              = var.location
  resource_group_name   = module.resource_group.name
  private_subnet_nsg_id = module.nsg.private_subnet_nsg_id
  hub_network           = local.hub_network
  tags                  = local.tags
}

module "tls" {
  source = "./tls"
}

module "vpn" {
  depends_on = [
    module.resource_group,
    module.vnets,
    module.tls
  ]
  source = "./vpn"

  name_prefix              = local.resource_prefix
  name_suffix              = local.resource_suffix
  location                 = var.location
  resource_group_name      = module.resource_group.name
  tags                     = local.tags
  hub_vnet_id              = module.vnets.hub_vnet_id
  gateway_subnet_id        = module.vnets.hub_gw_snet_id
  inbound_dns_subnet_id    = module.vnets.inbound_dns_snet_id
  public_root_cert_data    = module.tls.trimmed_cert
  vpn_client_address_pools = var.vpn_client_address_pools
}

module "container_registries" {
  depends_on = [module.resource_group, module.vnets]
  source     = "./container-registries"

  resource_group_name        = module.resource_group.name
  location                   = var.location
  name_prefix                = local.resource_prefix
  name_suffix                = local.resource_suffix
  tags                       = merge(local.tags, var.container_reg_tags)
  private_endpoint_subnet_id = module.vnets.resources_snet_id
  hub_vnet_name              = module.vnets.hub_vnet_name
  hub_vnet_id                = module.vnets.hub_vnet_id
}