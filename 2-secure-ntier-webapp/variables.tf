variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
  default     = "southeastasia"
}

variable "workload_name" {
  description = "Name of the workload to use in resource names."
  type        = string
  default     = "ntier"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network."
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "frontend_subnet_prefix" {
  description = "Address prefix for the Frontend VNet Integration subnet."
  type        = string
  default     = "10.1.1.0/24"
}

variable "backend_pe_subnet_prefix" {
  description = "Address prefix for the Backend Private Endpoint subnet."
  type        = string
  default     = "10.1.2.0/24"
}
