terraform {
  backend "azurerm" {
    resource_group_name  = "dso-terraform-state"
    storage_account_name = "digitalstudioinfradev"
    subscription_id      = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    container_name       = "offloc-stage"
    key                  = "offloc-stage-terraform.tfstate"
  }
}
