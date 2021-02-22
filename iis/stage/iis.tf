
locals {
  key_vault_secrets = ["signon-client-id", "signon-client-secret", "administrators"]
}

data "azurerm_key_vault_secret" "kv_secrets" {
  for_each     = toset(local.key_vault_secrets)
  name         = each.value
  key_vault_id = module.app_service.vault_id
}
module "app_service" {
  source                   = "../../shared/modules/azure-app-service"
  app                      = var.app
  env                      = var.env
  certificate_name         = var.certificate_name
  https_only               = true
  azure_jenkins_sp_oid     = var.azure_jenkins_sp_oid
  ip_restriction_addresses = var.ip_restriction_addresses
  sc_branch = var.sc_branch
  repo_url = var.repo_url
  log_containers           = var.log_containers
  sa_name = "${replace(local.name, "-", "")}storage"
  signon_hostname          = var.signon_hostname
  sampling_percentage      = var.sampling_percentage
  custom_hostname          = var.custom_hostname
  has_storage         = var.has_storage
  default_documents = [
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
  tags = {
    "application"      = "HPA"
    "environment_name" = "devtest"
    "service"          = "Misc"
  }
  app_settings = {
    DB_PASS        = random_id.sql-user-password.b64_url
    SESSION_SECRET = random_id.session-secret.b64_url
    ADMINISTRATORS                 = data.azurerm_key_vault_secret.kv_secrets["administrators"].value
    CLIENT_ID                      = data.azurerm_key_vault_secret.kv_secrets["signon-client-id"].value
    CLIENT_SECRET                  = data.azurerm_key_vault_secret.kv_secrets["signon-client-secret"].value
    DB_SERVER  = "${local.name}.database.windows.net"
    DB_USER    = "${var.app}user"
    DB_NAME    = local.name
    TOKEN_HOST = var.signon_hostname
  }
}

resource "random_id" "session-secret" {
  byte_length = 20
}
resource "random_id" "sql-user-password" {
  byte_length = 16
}

module "sql" {
  source              = "../../shared/modules/azure-sql"
  name                = local.name
  resource_group      = local.name
  location            = module.app_service.rg_location
  administrator_login = "iis"
  firewall_rules = [
    {
      label = "Open to the world"
      start = "0.0.0.0"
      end   = "255.255.255.255"
    },
  ]
  audit_storage_account = "${replace(local.name, "-", "")}storage"
  edition               = "Basic"
  scale                 = "Basic"
  collation             = "SQL_Latin1_General_CP1_CI_AS"
  tags = {
    application      = "HPA"
    environment_name = "devtest"
    service          = "Misc"
  }
}
output "advice" {
  value = "Don't forget to set up the SQL instance user/schemas manually."
}
