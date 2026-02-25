variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
  default     = "southeastasia"
}

variable "workload_name" {
  description = "Name of the workload to use in resource names."
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "pe_subnet_prefix" {
  description = "Address prefix for the Private Endpoint subnet."
  type        = string
  default     = "10.0.1.0/24"
}
