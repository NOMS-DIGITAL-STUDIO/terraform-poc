resource "azurerm_resource_group" "group" {
  name     = local.name
  location = "ukwest"
  tags     = var.tags
}

resource "azurerm_storage_account" "storage" {
  count = var.has_database ? 1 : 0
  name                     = "${replace(local.name, "-", "")}storage"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  account_tier             = "Standard"
  account_kind             = "Storage"
  account_replication_type = "RAGRS"
  tags                     = var.tags
}


resource "azurerm_storage_container" "logs" {
  count                 = length(var.log_containers)
  name                  = var.log_containers[count.index]
  storage_account_name  = "${replace(local.name, "-", "")}storage"
  container_access_type = "private"
}

resource "azurerm_key_vault" "vault" {
  name                = local.name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  sku_name            = "standard"
  tenant_id           = var.azure_tenant_id

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_webops_group_oid
    certificate_permissions = var.azure_certificate_permissions_all
    key_permissions         = []
    secret_permissions      = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    certificate_permissions = ["Get", "List", "Import"]
    key_permissions         = []
    secret_permissions      = ["Set", "Get"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.dso_certificates_oid
    certificate_permissions = ["get", "list", "import"]
    key_permissions         = []
    secret_permissions      = ["get"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}


resource "azurerm_app_service_plan" "webapp-plan" {
  name                = local.name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  kind                = var.app_service_kind
  tags                = var.tags
  sku {
    tier = var.app_service_plan_size == "B1" ? "Basic" : "Standard"
    size = var.app_service_plan_size
  }
}

resource "azurerm_app_service" "webapp" {
  name                = local.name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.webapp-plan.id
  tags                = var.tags
  https_only          = var.https_only
  client_cert_enabled = false

  site_config {
    http2_enabled               = var.http2_enabled
    scm_use_main_ip_restriction= var.scm_use_main_ip_restriction
    php_version               = "5.6"
    use_32_bit_worker_process = var.app_service_plan_size == "B1" ? true : false
    always_on                 = true
    default_documents         = var.default_documents
    dynamic "ip_restriction" {
      for_each = var.ip_restriction_addresses
      content {
        ip_address = ip_restriction.value
      }
    }
  }

  #Couldn't get logs to work as the sas token kept completing the apply, but reverting to file system logs
  #Instead needs to be enabled in the portal under app service logs -> "Web Service Logging" -> Storage -> "iisstagestorage" -> "web-logs"
  #  logs {
  #    http_logs {
  #      azure_blob_storage {
  #
  #        retention_in_days = 180
  #      }
  #    }
  #  }
  source_control {
    branch = var.sc_branch
    repo_url = var.repo_url
  }
  app_settings = merge({
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    WEBSITE_NODE_DEFAULT_VERSION   = "6.9.1"
  }, var.app_settings)
}
resource "azurerm_application_insights" "insights" {
  name                = local.name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
  retention_in_days   = 90
  sampling_percentage = var.sampling_percentage
  tags                = var.tags
}

resource "azurerm_app_service_certificate" "webapp-ssl" {
  name                = var.certificate_name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  tags                = var.tags
  #When you need to re-create add the key vault secret key id in, comment after so it doesn't get in the way of the plan or you'll need to main after every cert refresh
  key_vault_secret_id = var.certificate_kv_secret_id
}

resource "azurerm_app_service_certificate_binding" "binding" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.custom-binding.id
  certificate_id      = azurerm_app_service_certificate.webapp-ssl.id
  ssl_state           = "SniEnabled"
}

resource "azurerm_resource_group_template_deployment" "site-extension" {
  name                = "webapp-extension"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  #As all the module implementations have the same directory depth this is kept as is. Otherwise would need to set as variable
  template_content = file("../../shared/appservice-extension.template.json")

  parameters_content = jsonencode({
    name = { value = azurerm_app_service.webapp.name }
  })
  depends_on = [azurerm_app_service.webapp]
}
resource "azurerm_app_service_custom_hostname_binding" "custom-binding" {
  hostname            = var.custom_hostname
  app_service_name    = azurerm_app_service.webapp.name
  resource_group_name = azurerm_resource_group.group.name
}

output "advice" {
  value = "Don't forget to set up the SQL instance user/schemas manually."
}


output "rg_location" {
  value = azurerm_resource_group.group.location
}

output "app_service_outbound_ips" {
  value = azurerm_app_service.webapp.outbound_ip_address_list
}
