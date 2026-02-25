output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "outbound_app_url" {
  value = "https://${azurerm_linux_web_app.outbound_app.default_hostname}"
}

output "target_private_endpoint_ip" {
  value = azurerm_private_endpoint.target_pe.private_service_connection[0].private_ip_address
}
