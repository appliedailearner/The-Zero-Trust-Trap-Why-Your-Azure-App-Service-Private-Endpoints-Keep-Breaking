output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "frontend_app_url" {
  value = "https://${azurerm_linux_web_app.frontend_app.default_hostname}"
}

output "backend_private_endpoint_ip" {
  value = azurerm_private_endpoint.backend_pe.private_service_connection[0].private_ip_address
}
