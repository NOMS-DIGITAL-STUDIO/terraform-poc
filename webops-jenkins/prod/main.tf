variable "app_name" {
  type    = "string"
  default = "webops-jenkins-prod"
}

variable "tags" {
  type = "map"
  default {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "${var.app_name}"
  location = "ukwest"
  tags     = "${var.tags}"
}

resource "azurerm_dns_cname_record" "jenkins" {
  name                = "${var.app_name}"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "${var.app_name}.azurewebsites.net"
  tags                = "${var.tags}"
}

resource "azurerm_storage_account" "storage" {
    name = "${replace(var.app_name, "-", "")}storage"
    resource_group_name = "${azurerm_resource_group.group.name}"
    location = "${azurerm_resource_group.group.location}"
    account_tier = "Standard"
    account_replication_type = "RAGRS"
    enable_blob_encryption = true

    tags = "${var.tags}"
}

resource "azurerm_key_vault" "vault" {
  name                = "${var.app_name}"
  resource_group_name = "${azurerm_resource_group.group.name}"
  location            = "${azurerm_resource_group.group.location}"

  sku {
    name = "standard"
  }

  tenant_id = "${var.azure_tenant_id}"

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_webops_group_oid}"
    key_permissions    = []
    secret_permissions = "${var.azure_secret_permissions_all}"
  }

  access_policy {
    tenant_id          = "${var.azure_tenant_id}"
    object_id          = "${var.azure_app_service_oid}"
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
      tenant_id = "${var.azure_tenant_id}"
      object_id = "${var.azure_jenkins_sp_oid}"
      key_permissions = []
      secret_permissions = ["set"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = "${var.tags}"
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]
  query {
    vault = "${azurerm_key_vault.vault.name}"

    azure_sp_secret = "azure-sp-secret"
    azure_sp_clientid = "azure-sp-clientid"
    github_deploy_key = "github-deploy-key"
  }
}

module "docker_webapp" {
  source   = "../../shared/modules/azure-dockerapp"
  app_name = "${var.app_name}"
  binding_hostname = "${azurerm_dns_cname_record.jenkins.name}.${azurerm_dns_cname_record.jenkins.zone_name}"
  ssl_cert_keyvault = "${azurerm_key_vault.vault.id}"
  resource_group = "${azurerm_resource_group.group.name}"
  docker_image = "mojdigitalstudio/digital-studio-platform-jenkins:latest"
  app_settings {
    WEBSITE_PORTS = "8080"
    ENABLE_FULL_ADMIN = "false"
    AZURE_AD_OAUTH_ENABLE = "true"
    AZURE_TENANT_ID = "${var.azure_tenant_id}"
    AZURE_SP_SECRET = "${data.external.vault.result.azure_sp_secret}"
    AZURE_SP_CLIENT_ID = "${data.external.vault.result.azure_sp_clientid}"
    AZURE_AD_AUTH_GROUP = "${var.azure_webops_group_oid}"
    CERTBOT_REG_EMAIL = "noms-studio-webops@digital.justice.gov.uk"
    PIPELINES_GIT_REPO = "git@github.com:ministryofjustice/digital-studio-platform-pipelines.git"
    GITHUB_DEPLOY_KEY = "${data.external.vault.result.github_deploy_key}"
    SERVER_ENVIRONMENT = "production"
  }
  tags = "${var.tags}"
}
