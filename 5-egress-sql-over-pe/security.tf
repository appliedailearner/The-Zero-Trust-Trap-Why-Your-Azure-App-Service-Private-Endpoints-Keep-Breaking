# Network Security Group for App Service Subnet
resource "azurerm_network_security_group" "app_nsg" {
  name                = "nsg-app-vnetint-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "app_subnet_nsg" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# Network Security Group for SQL PE
resource "azurerm_network_security_group" "sql_pe_nsg" {
  name                = "nsg-sql-pe-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "sql_pe_subnet_nsg" {
  subnet_id                 = azurerm_subnet.sql_pe_subnet.id
  network_security_group_id = azurerm_network_security_group.sql_pe_nsg.id
}
