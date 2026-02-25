# Grant Function App access to Storage capabilities using Entra ID

resource "azurerm_role_assignment" "blob_owner" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_function_app.function.identity[0].principal_id
}

resource "azurerm_role_assignment" "queue_contrib" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_linux_function_app.function.identity[0].principal_id
}

resource "azurerm_role_assignment" "table_contrib" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_linux_function_app.function.identity[0].principal_id
}

resource "azurerm_role_assignment" "file_contrib" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_linux_function_app.function.identity[0].principal_id
}
