terraform {
  backend "azurerm" {
    resource_group_name  = "iis-prod"
    storage_account_name = "iisprodstorage"
    subscription_id      = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
    container_name       = "terraform"
    key                  = "iis-prod.terraform.tfstate"
  }
}
