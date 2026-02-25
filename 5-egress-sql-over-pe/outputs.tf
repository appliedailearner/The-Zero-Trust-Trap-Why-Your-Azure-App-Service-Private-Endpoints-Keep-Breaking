output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "web_app_url" {
  value = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "sql_server_private_endpoint_ip" {
  value = azurerm_private_endpoint.pe.private_service_connection[0].private_ip_address
}

output "sql_admin_password" {
  value     = random_password.sql_admin.result
  sensitive = true
}
