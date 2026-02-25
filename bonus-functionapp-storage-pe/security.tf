# Network Security Group for Function Subnet
resource "azurerm_network_security_group" "func_nsg" {
  name                = "nsg-func-vnetint-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "func_subnet_nsg" {
  subnet_id                 = azurerm_subnet.func_subnet.id
  network_security_group_id = azurerm_network_security_group.func_nsg.id
}

# Network Security Group for PE Subnet
resource "azurerm_network_security_group" "pe_nsg" {
  name                = "nsg-pe-storage-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "pe_subnet_nsg" {
  subnet_id                 = azurerm_subnet.pe_subnet.id
  network_security_group_id = azurerm_network_security_group.pe_nsg.id
}
