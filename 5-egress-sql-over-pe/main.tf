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

# Subnet for App Service VNet Integration
resource "azurerm_subnet" "app_subnet" {
  name                 = "snet-app-vnetint-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_subnet_prefix]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for SQL Private Endpoint
resource "azurerm_subnet" "sql_pe_subnet" {
  name                 = "snet-sql-pe-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.sql_pe_subnet_prefix]
}

# App Service Plan
resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "P1v3"
}

# Web App
resource "azurerm_linux_web_app" "app" {
  name                = "app-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.asp.id

  virtual_network_subnet_id = azurerm_subnet.app_subnet.id

  site_config {
    always_on              = true
    vnet_route_all_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }
}

# Random password for SQL Server admin
resource "random_password" "sql_admin" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-${var.workload_name}-${var.environment}-${var.location}-01"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin.result

  public_network_access_enabled = false
}

# SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name      = "sqldb-${var.workload_name}"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "S0"
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "link-vnet-${var.workload_name}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "pe" {
  name                = "pe-${azurerm_mssql_server.sql_server.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.sql_pe_subnet.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.id]
  }

  private_service_connection {
    name                           = "psc-${azurerm_mssql_server.sql_server.name}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
  }
}
