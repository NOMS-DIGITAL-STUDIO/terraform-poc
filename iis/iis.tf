
data "azurerm_key_vault_secret" "kv_secrets" {
  for_each     = toset(var.key_vault_secrets)
  name         = each.value
  key_vault_id = module.app_service.vault_id
}

resource "random_id" "session-secret" { byte_length = 20 }

module "app_service" {
  source = "../../shared/modules/azure-app-service"

  always_on = var.always_on
  app       = var.app
  app_settings = {
    # DB_PASS        = random_id.sql-users-passwords["iisuser"].b64_url
    DB_PASS        = local.db_pass
    SESSION_SECRET = random_id.session-secret.b64_url
    ADMINISTRATORS = data.azurerm_key_vault_secret.kv_secrets["administrators"].value
    CLIENT_ID      = data.azurerm_key_vault_secret.kv_secrets["signon-client-id"].value
    CLIENT_SECRET  = data.azurerm_key_vault_secret.kv_secrets["signon-client-secret"].value
    DB_SERVER      = "${local.name}.database.windows.net"
    DB_USER        = "${var.app}user"
    DB_NAME        = local.name
    TOKEN_HOST     = var.signon_hostname
  }
  app_service_plan_size        = var.app_service_plan_size
  azure_repo_app_principal_oid = var.azure_repo_app_principal_oid
  azure_jenkins_sp_oid         = var.azure_jenkins_sp_oid
  certificate_name             = var.certificate_name
  custom_hostname              = var.custom_hostname
  default_documents            = var.default_documents
  env                          = var.env
  has_storage                  = var.has_storage
  https_only                   = var.https_only
  ip_restriction_addresses     = local.ip_restriction_addresses
  key_vault_secrets            = var.key_vault_secrets
  log_containers               = var.log_containers
  repo_url                     = var.repo_url
  sa_name                      = "${replace(local.name, "-", "")}storage"
  sampling_percentage          = var.sampling_percentage
  sc_branch                    = var.sc_branch
  scm_use_main_ip_restriction  = var.scm_use_main_ip_restriction
  signon_hostname              = var.signon_hostname
  tags                         = var.tags
  use_32_bit_worker_process    = var.use_32_bit_worker_process
}

# locals {
#   use this commented out bit if we get users from list var
#     db_user_passwords = [
#       for user in var.sql_users :
#       random_id.sql-users-passwords[user].b64_url
#     ]
#     db_users = zipmap(
#       var.sql_users,
#       local.db_user_passwords
#     )
# }

module "sql" {
  source = "../../shared/modules/azure-sql"

  name                  = local.name
  resource_group        = local.name
  location              = module.app_service.rg_location
  administrator_login   = var.app
  firewall_rules        = local.firewall_rules
  audit_storage_account = "${replace(local.name, "-", "")}storage"
  edition               = var.sql_edition
  scale                 = var.sql_scale
  space_gb              = var.sql_space_gb
  collation             = var.sql_collation
  db_users              = local.db_users
  setup_queries         = var.setup_queries
  tags                  = var.tags
}

# you may need to do a target apply on the app service first if building from scratch
resource "azurerm_sql_firewall_rule" "app-access" {
  count               = var.create_sql_firewall ? length(module.app_service.app_service_outbound_ips) : 0
  name                = "Application IP ${count.index}"
  resource_group_name = local.name
  server_name         = local.name
  start_ip_address    = module.app_service.app_service_outbound_ips[count.index]
  end_ip_address      = module.app_service.app_service_outbound_ips[count.index]
  depends_on          = [module.app_service.webapp]
}

resource "azurerm_dns_cname_record" "cname" {
  count               = var.create_cname ? 1 : 0
  name                = local.dns_name
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "${local.name}.azurewebsites.net"
}

output "advice" {
  value = [
    "Don't forget to set up the SQL instance user/schemas manually.",
    "Application Insights continuous export must also be done manually"
  ]
}
