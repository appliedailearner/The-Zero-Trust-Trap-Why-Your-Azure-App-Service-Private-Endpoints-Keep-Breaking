# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.workload_name}-${var.environment}-${var.location}-01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Diagnostic Setting for Frontend App
resource "azurerm_monitor_diagnostic_setting" "frontend_app_diag" {
  name                       = "diag-${azurerm_linux_web_app.frontend_app.name}"
  target_resource_id         = azurerm_linux_web_app.frontend_app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic Setting for Backend App
resource "azurerm_monitor_diagnostic_setting" "backend_app_diag" {
  name                       = "diag-${azurerm_linux_web_app.backend_app.name}"
  target_resource_id         = azurerm_linux_web_app.backend_app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
