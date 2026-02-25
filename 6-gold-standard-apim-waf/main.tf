resource "azurerm_resource_group" "main" {
  name     = "rg-${var.workload_name}-${var.environment}-${var.location}-01"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.workload_name}-${var.environment}-${var.location}-01"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet for App Gateway
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "snet-appgw-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.appgw_subnet_prefix]
}

# Subnet for APIM (Must use Microsoft.ApiManagement delegation on newer API versions or have NSG setup)
resource "azurerm_subnet" "apim_subnet" {
  name                 = "snet-apim-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.apim_subnet_prefix]
}

# Subnet for App Service Private Endpoint
resource "azurerm_subnet" "pe_subnet" {
  name                 = "snet-pe-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.pe_subnet_prefix]
}

# App Service Plan
resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "P1v3"
}

# Backend Web App (Isolated)
resource "azurerm_linux_web_app" "app" {
  name                = "app-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.asp.id

  public_network_access_enabled = false

  site_config {
    always_on = true
  }
}

# DNS for Web App
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "link-vnet-${var.workload_name}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "pe" {
  name                = "pe-${azurerm_linux_web_app.app.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.id]
  }

  private_service_connection {
    name                           = "psc-${azurerm_linux_web_app.app.name}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_web_app.app.id
    subresource_names              = ["sites"]
  }
}

# Public IP for APIM (Required even for internal VNet mode for management traffic)
resource "azurerm_public_ip" "apim_pip" {
  name                = "pip-apim-${var.workload_name}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "apim-mgmt-${var.workload_name}-${var.location}"
}

# API Management (Internal VNet Mode) - Note: Developer tier is used for cost savings in non-prod
resource "azurerm_api_management" "apim" {
  name                = "apim-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  publisher_name      = "Company Setup"
  publisher_email     = "admin@company.test"
  sku_name            = "Developer_1"

  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim_subnet.id
  }

  public_ip_address_id = azurerm_public_ip.apim_pip.id
}

# Public IP for App Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-appgw-${var.workload_name}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway WAF v2
resource "azurerm_application_gateway" "appgw" {
  name                = "agw-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend_ip_config"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  # Backend pool points to APIM's internal private IP
  backend_address_pool {
    name         = "apim-backend-pool"
    ip_addresses = azurerm_api_management.apim.private_ip_addresses
  }

  backend_http_settings {
    name                                = "https_backend_setting"
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 60
    pick_host_name_from_backend_address = false
    host_name                           = trimprefix(trimprefix(azurerm_api_management.apim.gateway_url, "https://"), "http://")
  }

  http_listener {
    name                           = "listener_80"
    frontend_ip_configuration_name = "frontend_ip_config"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "route_rule"
    rule_type                  = "Basic"
    http_listener_name         = "listener_80"
    backend_address_pool_name  = "apim-backend-pool"
    backend_http_settings_name = "https_backend_setting"
    priority                   = 100
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
}
