
resource "azurerm_key_vault" "ssl_az_justice_gov_uk" {
  name                = "certs-az-justice-gov-uk"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  soft_delete_enabled = true
  sku_name            = "standard"

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "a3186d6c-b760-4cc4-b3f2-83fbafbd101a"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "8ec82615-1643-4fb6-9aaa-2c68fac3c0b7"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "376d3da7-a43f-4650-b990-744869194d1b"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "8a65aed7-e34f-4988-8b90-2a2fcc41e355"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "d0e78d36-5642-4463-9a74-adf4f4c60f0a"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "f31ec979-bd0f-48f3-b1fc-35026a437c50"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "4792da74-5a2c-4aca-888b-13d8eb59af38"
    key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"]
    secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
    certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "52100d14-6c85-46f9-bd65-864ffb3eeaa3"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "8363f4bd-7a4f-4b4a-9cbd-97b343900a10"
    key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"]
    secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
    certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_webops_group_oid
    key_permissions         = ["Get", "List", "Update", "Create", "Import"]
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_app_service_oid
    key_permissions         = []
    secret_permissions      = ["Get"]
    certificate_permissions = ["Get"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    key_permissions         = []
    secret_permissions      = ["Get", "Set"]
    certificate_permissions = ["Get", "List", "Import"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "5657dd88-834a-4007-8a2a-88397be8c27a"
    key_permissions         = []
    secret_permissions      = ["Get", "Set", "Delete"]
    certificate_permissions = []
  }
  # PoshACME
  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "3f055065-e863-4368-8dac-240fa40ac4ed"
    key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"]
    secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
    certificate_permissions = var.azure_certificate_permissions_all
  }

  # cert-githubaction
  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "c99ff8c7-6ea9-41f0-b74c-05a25cb025dd"
    key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"]
    secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
    certificate_permissions = var.azure_certificate_permissions_all
  }

  # digital-studio-webops-jenkins-prod
  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "d064748a-9f4a-4cc9-b33e-d4e80d049221"
    key_permissions         = []
    secret_permissions      = ["Get", "Set"]
    certificate_permissions = ["Get", "List", "Import"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}
