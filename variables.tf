###########################################################
#  Common
###########################################################
variable "location" {
  description = "(required) Region to create the resource"
  type        = string
}

variable "ARM_CLIENT_ID" {
  description = "(required) Client ID for Azure app registration"
  type        = string
}

variable "ARM_CLIENT_SECRET" {
  description = "(required) Client secret for Azure app registration"
  type        = string
}

variable "ARM_TENANT_ID" {
  description = "(required) Tenant ID for Azure"
  type        = string
}

variable "ARM_SUBSCRIPTION_ID" {
  description = "(required) Subscription ID for Azure"
  type        = string
}

variable "jira_project_id" {
  description = "(required) Jira Project ID used as a suffix for most resource names"
  type        = string
}

variable "project_name" {
  description = "(required) Project name mostly used as a prefix for resource names"
  type        = string
}

variable "resource_group_tags" {
  description = "(optional) Some useful information"
  type        = map(any)
  default     = {}
}

###########################################################
#  VNets
###########################################################
variable "hub_vnet" {
  description = "(required) CIDR Range of the Hub VNet"
  type        = string
}

###########################################################
#  VPN
###########################################################
variable "vpn_client_address_pools" {
  description = "(required) List of address pools to use for VPN clients"
  type        = string
}

###########################################################
#  Container Registries
###########################################################
variable "container_reg_tags" {
  description = "(optional) Some useful information"
  type        = map(any)
  default     = {}
}