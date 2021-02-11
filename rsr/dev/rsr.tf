variable "app-name" {
  type    = string
  default = "rsr-dev"
}

variable "tags" {
  type = map

  default = { "application" = "RSR"
    "environment_name" = "devtest"
    "service"          = "Misc"
  }

}

resource "azurerm_resource_group" "group" {
  name     = var.app-name
  location = "ukwest"
  tags     = var.tags
}

resource "azurerm_app_service_plan" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  sku {
    tier     = "Basic"
    size     = "B1"
    capacity = 1
  }
  tags = var.tags
}

resource "azurerm_app_service" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.app.id
  https_only          = true
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
  http2_enabled               = true
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
  sampling_percentage                   = 100
  tags = var.tags
}

resource "azurerm_key_vault" "vault" {
  name                = var.app-name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  sku_name            = "standard"

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_webops_group_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_aap_group_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_jenkins_sp_oid
    key_permissions    = []
    secret_permissions = ["set", "get"]
    certificate_permissions = [
        "Get", "Import","List",
      ]
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

resource "azurerm_app_service_certificate" "webapp-ssl" {
  name                = "rsr-dev-rsr-dev-CERTrsr-devDOThmppsDOTdsdDOTio"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  tags                = var.tags
  #When you need to re-create add the key vault secret key id in, comment after so it doesn't get in the way of the plan or you'll need to main after every cert refresh
  #key_vault_secret_id = "https://rsr-dev.vault.azure.net/secrets/rsr-dev-rsr-dev-CERTrsr-devDOThmppsDOTdsdDOTio"
}


resource "azurerm_app_service_certificate_binding" "binding" {
  hostname_binding_id = "/subscriptions/c27cfedb-f5e9-45e6-9642-0fad1a5c94e7/resourceGroups/rsr-dev/providers/Microsoft.Web/sites/rsr-dev/hostNameBindings/rsr-dev.hmpps.dsd.io"
  certificate_id      = "/subscriptions/c27cfedb-f5e9-45e6-9642-0fad1a5c94e7/resourceGroups/rsr-dev/providers/Microsoft.Web/certificates/rsr-dev-rsr-dev-CERTrsr-devDOThmppsDOTdsdDOTio"
  ssl_state           = "SniEnabled"
}

resource "azurerm_app_service_custom_hostname_binding" "custom-binding" {
  hostname            = "rsr-dev.hmpps.dsd.io"
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


resource "github_repository_webhook" "rsr-deploy" {
  repository = "rsr-calculator-service"
  configuration {
    #hardcoded if this is ever rebuilt will need to be updated
    url          = "https://$rsr-dev:xfyC59uSQz6pakG3981G86u261Bh7yiuHLmYaqndksjPtGGDuDbeLeQNcLGa@rsr-dev.scm.azurewebsites.net/deploy?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}
