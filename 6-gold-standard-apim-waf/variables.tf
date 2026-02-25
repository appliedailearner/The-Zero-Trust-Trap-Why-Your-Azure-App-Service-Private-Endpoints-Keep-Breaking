variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
  default     = "southeastasia"
}

variable "workload_name" {
  description = "Name of the workload to use in resource names."
  type        = string
  default     = "goldstd"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

# APIM requires a /29 minimum, AppGW requires /24
variable "vnet_address_space" {
  description = "Address space for the Virtual Network."
  type        = list(string)
  default     = ["10.5.0.0/16"]
}

variable "appgw_subnet_prefix" {
  description = "Address prefix for the App Gateway subnet."
  type        = string
  default     = "10.5.1.0/24"
}

variable "apim_subnet_prefix" {
  description = "Address prefix for the APIM subnet."
  type        = string
  default     = "10.5.2.0/24"
}

variable "pe_subnet_prefix" {
  description = "Address prefix for the Web App PE subnet."
  type        = string
  default     = "10.5.3.0/24"
}
