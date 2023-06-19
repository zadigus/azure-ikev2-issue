variable "resource_group_name" {
  description = "(required) Name of the target Resource Group"
  type        = string
}

variable "name_prefix" {
  description = "(required) Name of the Storage Account to deploy"
  type        = string
}

variable "name_suffix" {
  description = "(required) Suffix of the Name of the Storage Account to deploy"
  type        = string
}

variable "location" {
  description = "(required) Location of Storage Account deployment"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "(optional) Some useful information"
  type        = map(any)
  default     = {}
}

variable "gateway_subnet_id" {
  description = "(required) The subnet ID where the network gateway should come in"
  type        = string
}

variable "inbound_dns_subnet_id" {
  description = "(required) The subnet ID where the inbound endpoint"
  type        = string
}

variable "hub_vnet_id" {
  description = "(required) The Hub Vnet ID"
  type        = string
}

variable "public_root_cert_data" {
  description = "(required) Public CA certificate in base-64 encoded X.509 format (PEM)"
  type        = string
}

variable "vpn_client_address_pools" {
  description = "(required) Address space for VPN clients, e.g. in CIDR notation"
  type        = string
}