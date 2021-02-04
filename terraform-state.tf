resource "azurerm_storage_account" "webops" {
  name                     = "nomsstudiowebops"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  account_kind             = "BlobStorage"
  account_tier             = "Standard"
  account_replication_type = "GRS"
  access_tier              = "Hot"
  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}
