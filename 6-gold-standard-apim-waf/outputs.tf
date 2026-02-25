output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "apim_private_ip" {
  value = azurerm_api_management.apim.private_ip_addresses[0]
}

output "web_app_private_endpoint_ip" {
  value = azurerm_private_endpoint.pe.private_service_connection[0].private_ip_address
}
