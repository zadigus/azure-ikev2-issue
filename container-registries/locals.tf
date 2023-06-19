locals {
  container_reg_name = format(
    "%s%s",
    var.name_prefix,
    var.name_suffix
  )
}