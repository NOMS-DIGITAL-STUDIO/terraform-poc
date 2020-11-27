resource "azurerm_storage_account" "webops" {
  name                      = "nomsstudiowebopsprod"
  resource_group_name       = azurerm_resource_group.group.name
  location                  = azurerm_resource_group.group.location
  account_kind              = "BlobStorage"
  account_tier              = "Standard"
  enable_https_traffic_only = false
  account_replication_type  = "GRS"
  access_tier               = "Hot"
  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_storage_container" "terraform" {
  name                  = "terraform"
  storage_account_name  = azurerm_storage_account.webops.name
  container_access_type = "private"
}
