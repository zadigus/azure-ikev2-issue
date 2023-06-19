locals {
  resource_prefix             = lower(replace(var.project_name, "/\\W|_|\\s/", ""))
  resource_suffix             = lower(replace(var.jira_project_id, "/\\W|_|\\s/", ""))
  environment                 = "dev"
  tags                        = {
    "monitoring"  = "true"
    "Owner"       = "MDL"
    "Env_Name"    = local.environment
    "Project_Name" = var.project_name
  }

  hub_network = {
    "vnet" : var.hub_vnet
    "inbounddns": cidrsubnet(var.hub_vnet, 4, 0)
    "vpn_gateway" : cidrsubnet(var.hub_vnet, 4, 2)
    "resources" : cidrsubnet(var.hub_vnet, 4, 4)
  }
}