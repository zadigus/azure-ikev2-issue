locals {
  resource_group_name = format(
    "%s_hub_rg",
    var.group_prefix,
  )
}