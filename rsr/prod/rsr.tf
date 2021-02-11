variable "app-name" {
  type    = string
  default = "rsr-prod"
}

variable "tags" {
  type = map

  default = { "application" = "RSR"
    "environment_name" = "prod"
    "service"          = "Misc"
  }
}

resource "azurerm_resource_group" "group" {
  name     = var.app-name
  location = "ukwest"
  tags     = var.tags
}


resource "azurerm_key_vault" "vault" {
  name                = var.app-name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  sku_name            = "standard"

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_webops_group_oid
    certificate_permissions = var.azure_certificate_permissions_all
    key_permissions         = []
    secret_permissions      = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    certificate_permissions = ["Get", "List", "Import"]
    key_permissions         = []
    secret_permissions      = ["Set", "Get"]
  }
  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.dso_certificates_oid
    certificate_permissions = ["get", "list", "import"]
    key_permissions         = []
    secret_permissions      = ["get", "set"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}

resource "azurerm_app_service_plan" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  tags = var.tags
  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }
}
#Sometimes if you apply this resource the scm type will get unset with an error.
#Re-running the apply will fix this. Ideally this should have an scm tpye github.
resource "azurerm_app_service" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.app.id
  tags = var.tags
  site_config {
  scm_type                    = "LocalGit"
  always_on                   = true
  default_documents           = [
    "Default.htm",
    "Default.html",
    "Default.asp",
    "index.htm",
    "index.html",
    "iisstart.htm",
    "default.aspx",
     "index.php",
    "hostingstart.html",
  ]
  php_version                 = "5.6"
  use_32_bit_worker_process   = true
  }
  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION   = "6.9.1"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
  }
}

resource "azurerm_application_insights" "insights" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
  retention_in_days   = 90
  sampling_percentage = 50
  tags = var.tags
}

resource "azurerm_app_service_certificate" "webapp-ssl" {
  name                = "rsr-prod-rsr-prod-CERTrsrDOTserviceDOThmppsDOTdsdDOTio"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  tags                = var.tags
  #When you need to re-create add the key vault secret key id in, comment after so it doesn't get in the way of the plan or you'll need to main after every cert refresh
  #key_vault_secret_id = "https://rsr-prod.vault.azure.net/secrets/rsr-prod-rsr-prod-CERTrsr-prodDOThmppsDOTdsdDOTio"
}


resource "azurerm_app_service_certificate_binding" "binding" {
  hostname_binding_id = "/subscriptions/a5ddf257-3b21-4ba9-a28c-ab30f751b383/resourceGroups/rsr-prod/providers/Microsoft.Web/sites/rsr-prod/hostNameBindings/rsr.service.hmpps.dsd.io"
  certificate_id      = "/subscriptions/a5ddf257-3b21-4ba9-a28c-ab30f751b383/resourceGroups/rsr-prod/providers/Microsoft.Web/certificates/rsr-prod-rsr-prod-CERTrsrDOTserviceDOThmppsDOTdsdDOTio"
  ssl_state           = "SniEnabled"
}

resource "azurerm_app_service_custom_hostname_binding" "custom-binding" {
  hostname            = "rsr.service.hmpps.dsd.io"
  app_service_name    = azurerm_app_service.app.name
  resource_group_name = azurerm_resource_group.group.name
}

#no terraform resource for site extensions https://github.com/terraform-providers/terraform-provider-azurerm/issues/2328
#the extension no longer exists in the extension list so if this is ever re-built we'd need to find a new extension to do the redirect, keeping for now as it's whats live
resource "azurerm_resource_group_template_deployment" "site-extension" {
  name                = "webapp-extension"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_content    = file("../../shared/appservice-extension.template.json")

  # documentation for the new resource_group_template_deployment isn't great, it needs a json list so you write it in terraform then json encode it
  parameters_content = jsonencode({
    name = { value = azurerm_app_service.app.name }
  })
  depends_on = [azurerm_app_service.app]
}
