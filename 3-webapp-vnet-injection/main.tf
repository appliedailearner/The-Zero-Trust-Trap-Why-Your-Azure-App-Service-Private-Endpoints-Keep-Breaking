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

# Subnet for VNet Integration
resource "azurerm_subnet" "integration_subnet" {
  name                 = "snet-integration-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.integration_subnet_prefix]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for Target Private Endpoint
resource "azurerm_subnet" "target_pe_subnet" {
  name                 = "snet-pe-target-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.target_pe_subnet_prefix]
}

# App Service Plan
resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "P1v3"
}

# Outbound Web App (VNet Integrated, Public Access Enabled for testing ingress)
resource "azurerm_linux_web_app" "outbound_app" {
  name                = "app-${var.workload_name}-outbound-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.asp.id

  virtual_network_subnet_id = azurerm_subnet.integration_subnet.id

  site_config {
    always_on              = true
    vnet_route_all_enabled = true
  }
}

# Target Web App (Public Network Access Disabled) represents downstream dependency
resource "azurerm_linux_web_app" "target_app" {
  name                = "app-${var.workload_name}-target-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.asp.id

  public_network_access_enabled = false

  site_config {
    always_on = true
  }
}

# Private DNS Zone for App Service
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "link-vnet-${var.workload_name}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Private Endpoint for Target Web App
resource "azurerm_private_endpoint" "target_pe" {
  name                = "pe-${azurerm_linux_web_app.target_app.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.target_pe_subnet.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.id]
  }

  private_service_connection {
    name                           = "psc-${azurerm_linux_web_app.target_app.name}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_web_app.target_app.id
    subresource_names              = ["sites"]
  }
}
