# Network Security Group
resource "azurerm_network_security_group" "pe_nsg" {
  name                = "nsg-pe-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# NSG Association
resource "azurerm_subnet_network_security_group_association" "pe_subnet_nsg" {
  subnet_id                 = azurerm_subnet.pe_subnet.id
  network_security_group_id = azurerm_network_security_group.pe_nsg.id
}
