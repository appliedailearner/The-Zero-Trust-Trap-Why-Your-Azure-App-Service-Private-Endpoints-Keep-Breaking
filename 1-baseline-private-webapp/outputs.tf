output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "app_service_name" {
  value = azurerm_linux_web_app.app.name
}

output "private_endpoint_ip" {
  value = azurerm_private_endpoint.pe.private_service_connection[0].private_ip_address
}
