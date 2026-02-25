variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
  default     = "southeastasia"
}

variable "workload_name" {
  description = "Name of the workload to use in resource names."
  type        = string
  default     = "funcstr"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network."
  type        = list(string)
  default     = ["10.6.0.0/16"]
}

variable "func_vnetint_subnet_prefix" {
  description = "Address prefix for the Function App VNet Integration subnet."
  type        = string
  default     = "10.6.1.0/24"
}

variable "pe_subnet_prefix" {
  description = "Address prefix for the Storage Private Endpoints subnet."
  type        = string
  default     = "10.6.2.0/24"
}
