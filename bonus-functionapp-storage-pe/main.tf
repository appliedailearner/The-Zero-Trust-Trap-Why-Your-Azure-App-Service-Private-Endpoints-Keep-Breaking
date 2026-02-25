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

# Subnet for Function App VNet Integration
resource "azurerm_subnet" "func_subnet" {
  name                 = "snet-func-vnetint-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.func_vnetint_subnet_prefix]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet for Storage Private Endpoints
resource "azurerm_subnet" "pe_subnet" {
  name                 = "snet-storage-pe-${var.location}-01"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.pe_subnet_prefix]
}

# Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "st${var.workload_name}${var.environment}01"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = false
}

# DNS Zones for Storage (Blob, File, Queue, Table)
resource "azurerm_private_dns_zone" "dns_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "dns_file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "dns_queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "dns_table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

# DNS Zone Links
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_blob" {
  name                  = "link-vnet-blob"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_file" {
  name                  = "link-vnet-file"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_file.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_queue" {
  name                  = "link-vnet-queue"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_queue.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link_table" {
  name                  = "link-vnet-table"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_table.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Private Endpoints
locals {
  storage_services = {
    blob  = azurerm_private_dns_zone.dns_blob.id
    file  = azurerm_private_dns_zone.dns_file.id
    queue = azurerm_private_dns_zone.dns_queue.id
    table = azurerm_private_dns_zone.dns_table.id
  }
}

resource "azurerm_private_endpoint" "storage_pes" {
  for_each            = local.storage_services
  name                = "pe-storage-${each.key}-${var.workload_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [each.value]
  }

  private_service_connection {
    name                           = "psc-storage-${each.key}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = [each.key]
  }
}

# App Service Plan (Elastic Premium)
resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "EP1"
}

# Function App
resource "azurerm_linux_function_app" "function" {
  name                = "func-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.asp.id

  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  virtual_network_subnet_id = azurerm_subnet.func_subnet.id

  site_config {
    always_on              = false
    vnet_route_all_enabled = true

    application_stack {
      python_version = "3.10"
    }
  }

  app_settings = {
    "WEBSITE_VNET_ROUTE_ALL"   = "1"
    "WEBSITE_CONTENTOVERVNET"  = "1"
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    # Additional required settings for secure storage
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.storage.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = "func-content-share"
  }

  depends_on = [
    azurerm_private_endpoint.storage_pes
  ]
}
