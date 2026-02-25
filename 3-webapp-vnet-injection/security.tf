# Network Security Group for Integration Subnet
resource "azurerm_network_security_group" "integration_nsg" {
  name                = "nsg-integration-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "integration_subnet_nsg" {
  subnet_id                 = azurerm_subnet.integration_subnet.id
  network_security_group_id = azurerm_network_security_group.integration_nsg.id
}

# Network Security Group for Target PE
resource "azurerm_network_security_group" "target_pe_nsg" {
  name                = "nsg-pe-target-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "target_pe_subnet_nsg" {
  subnet_id                 = azurerm_subnet.target_pe_subnet.id
  network_security_group_id = azurerm_network_security_group.target_pe_nsg.id
}
