resource "azurerm_resource_group" "group" {
  name     = local.name
  location = "ukwest"
  tags     = local.tags
}

resource "azurerm_storage_account" "storage" {
  name                      = local.storage
  resource_group_name       = azurerm_resource_group.group.name
  location                  = azurerm_resource_group.group.location
  account_tier              = "Standard"
  account_replication_type  = "RAGRS"
  enable_https_traffic_only = true

  tags = local.tags
}

resource "azurerm_key_vault" "vault" {
  name                = local.name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location

  sku_name = "standard"

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_webops_group_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_jenkins_sp_oid
    key_permissions    = []
    secret_permissions = ["set"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = local.app_team_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  tags                            = local.tags
}

resource "random_id" "session" {
  byte_length = 40
}

resource "azurerm_app_service_plan" "app" {
  name                = local.name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  sku {
    tier     = "Standard"
    size     = local.app_size
    capacity = local.app_count
  }

  tags = local.tags
}

resource "azurerm_application_insights" "insights" {
  name                = local.name
  location            = "North Europe"
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
}

resource "azurerm_app_service" "app" {
  name                = local.name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.app.id
  https_only          = true

  tags = local.tags

  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION   = "8.4.0"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    NODE_ENV                       = "production"
    SESSION_SECRET                 = random_id.session.b64_std
    AZURE_STORAGE_CONTAINER_NAME   = "cde"
    AZURE_STORAGE_RESOURCE_GROUP   = azurerm_resource_group.group.name
    AZURE_STORAGE_ACCOUNT_NAME     = azurerm_storage_account.app.name
    AZURE_STORAGE_SUBSCRIPTION_ID  = var.azure_subscription_id
    WEBSITE_TIME_ZONE              = "GMT Standard Time"

    # Can't use resource property here otherwise we create a dependency cycle
    KEY_VAULT_URL = "https://${local.name}-users.vault.azure.net/"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account" "app" {
  name                      = "${replace(local.name, "-", "")}app"
  resource_group_name       = azurerm_resource_group.group.name
  location                  = azurerm_resource_group.group.location
  account_tier              = "Standard"
  account_replication_type  = "RAGRS"
  enable_https_traffic_only = true

  tags = local.tags
}

resource "azurerm_role_assignment" "jenkins-write-storage" {
  scope                = azurerm_storage_account.app.id
  role_definition_name = "Contributor"
  principal_id         = local.azure_fixngo_jenkins_oid
}

resource "azurerm_role_assignment" "app-read-storage" {
  scope                = azurerm_storage_account.app.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = azurerm_app_service.app.identity.0.principal_id
}

resource "azurerm_key_vault" "app" {
  name                = "${local.name}-users"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location

  sku_name = "standard"

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_webops_group_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = local.app_team_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = azurerm_app_service.app.identity.0.tenant_id
    object_id          = azurerm_app_service.app.identity.0.principal_id
    key_permissions    = []
    secret_permissions = ["get", "set", "list", "delete"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  tags                            = local.tags
}

resource "azurerm_dns_cname_record" "app" {
  name                = local.cname
  zone_name           = local.dns_zone_name
  resource_group_name = local.dns_zone_rg
  ttl                 = "300"
  record              = "${local.name}.azurewebsites.net"
  tags                = local.tags
}

resource "azurerm_dns_zone" "extra" {
  count               = local.extra_dns_zone == "" ? 0 : 1
  name                = local.extra_dns_zone
  resource_group_name = azurerm_resource_group.group.name
  tags                = local.tags
}

resource "azurerm_dns_cname_record" "extra" {
  count               = local.extra_dns_zone == "" ? 0 : 1
  name                = "www"
  zone_name           = azurerm_dns_zone.extra[count.index].name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"
  record              = "${local.name}.azurewebsites.net"
  tags                = local.tags
}

resource "azurerm_template_deployment" "ssl" {
  name                = "ssl"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-tls10.template.json")

  parameters = {
    name             = azurerm_app_service.app.name
    hostname         = "${azurerm_dns_cname_record.app.name}.${azurerm_dns_cname_record.app.zone_name}"
    keyVaultId       = azurerm_key_vault.vault.id
    keyVaultCertName = replace("${azurerm_dns_cname_record.app.name}.${azurerm_dns_cname_record.app.zone_name}", ".", "DOT")
    service          = local.tags["Service"]
    environment      = local.tags["Environment"]
  }
}

resource "azurerm_template_deployment" "ssl-extra" {
  count               = local.extra_dns_zone == "" ? 0 : 1
  name                = "ssl-extra"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-tls10.template.json")

  parameters = {
    name             = azurerm_app_service.app.name
    hostname         = "${azurerm_dns_cname_record.extra[count.index].name}.${azurerm_dns_cname_record.extra[count.index].zone_name}"
    keyVaultId       = azurerm_key_vault.vault.id
    keyVaultCertName = replace("${azurerm_dns_cname_record.extra[count.index].name}.${azurerm_dns_cname_record.extra[count.index].zone_name}", ".", "DOT")
    service          = local.tags["Service"]
    environment      = local.tags["Environment"]

    # This forces the app service to have a static public IP address
    sslState = "IpBasedEnabled"
  }
}

resource "azurerm_template_deployment" "github" {
  count               = local.github_deploy_branch == "" ? 0 : 1
  name                = "github"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-scm.template.json")

  parameters = {
    name    = azurerm_app_service.app.name
    repoURL = "https://github.com/ministryofjustice/offloc-server.git"
    branch  = local.github_deploy_branch
  }
}

resource "github_repository_webhook" "deploy" {
  count      = local.github_deploy_branch == "" ? 0 : 1
  repository = "offloc-server"

  configuration {
    url          = "${azurerm_template_deployment.github[count.index].outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}

module "slackhook" {
  source             = "../../shared/modules/slackhook"
  app_name           = azurerm_app_service.app.name
  channels           = var.deployment-channels
  azure_subscription = local.azure_subscription
}
