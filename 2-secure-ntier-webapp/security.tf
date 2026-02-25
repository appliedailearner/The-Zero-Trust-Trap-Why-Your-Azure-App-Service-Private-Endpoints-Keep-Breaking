# Network Security Group for Frontend
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "nsg-frontend-vnetint-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "frontend_subnet_nsg" {
  subnet_id                 = azurerm_subnet.frontend_subnet.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

# Network Security Group for Backend PE
resource "azurerm_network_security_group" "backend_pe_nsg" {
  name                = "nsg-backend-pe-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "backend_pe_subnet_nsg" {
  subnet_id                 = azurerm_subnet.backend_pe_subnet.id
  network_security_group_id = azurerm_network_security_group.backend_pe_nsg.id
}
