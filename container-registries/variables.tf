variable "resource_group_name" {
  description = "(required) Name of the target Resource Group"
  type        = string
}

variable "name_prefix" {
  description = "(required) Name Prefix of the Resource"
  type        = string
}

variable "name_suffix" {
  description = "(required) Name Suffix of the Resource"
  type        = string
}

variable "location" {
  description = "(required) Location of the target Container Registries"
  type        = string
}

variable "tags" {
  description = "(optional) Some useful information"
  type        = map(any)
  default     = {}
}

variable "private_endpoint_subnet_id" {
  description = "(required) The subnet ID where the ACR should come in"
  type        = string
}

variable "hub_vnet_name" {
    description = "(required) The name of the Hub VNet"
    type        = string
}

variable "hub_vnet_id" {
  description = "(required) The ID of the Hub VNet"
  type        = string
}