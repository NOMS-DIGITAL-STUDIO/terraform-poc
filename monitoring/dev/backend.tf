terraform {
  backend "azurerm" {
    resource_group_name  = "iis-stage"
    storage_account_name = "iisstagestorage"
    subscription_id      = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    container_name       = "terraform"
    key                  = "iis-stage.terraform.tfstate"
  }
}
