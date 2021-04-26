locals {
  env-name = "devtest"
}

variable "tags" {
  type = map(any)
}

resource "azurerm_resource_group" "group" {
  name     = "webops-shared-dns-devtest"
  location = "ukwest"
  tags     = var.tags
}

resource "azurerm_storage_container" "terraform" {
  name                  = "webops-dev"
  storage_account_name  = "digitalstudioinfradev"
  container_access_type = "private"
}
