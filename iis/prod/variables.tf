##
# Have no defaults

# TODO note which are from app module, and possibly take them out of here because they are defined in module variables.tf

variable "always_on" { type = bool }
variable "app" { type = string }
variable "app_service_plan_size" { type = string }
variable "certificate_name" { type = string }
variable "create_cname" { type = bool }
variable "create_sql_firewall" { type = bool }
variable "custom_hostname" { type = string }
variable "env" { type = string }
variable "https_only" { type = bool }
variable "key_vault_secrets" { type = list(string) }
variable "repo_url" { type = string }
variable "sc_branch" { type = string }
variable "setup_queries" { type = list(string) }
variable "sql_collation" { type = string }
variable "sql_edition" { type = string }
variable "sql_scale" { type = string }
variable "sql_space_gb" { type = number }
variable "sql_users" { type = list(string) }
variable "tags" { type = map(any) }
variable "use_32_bit_worker_process" { type = bool }

variable "default_documents" {
  type        = list(string)
  description = "default documents for the app site config"
}

variable "has_storage" {
  type        = bool
  description = "If the app service creates a sql server and DB with the app service"
}

variable "sampling_percentage" {
  type        = string
  description = "Fixed rate samping for app insights for reduing volume of telemetry"
}

variable "signon_hostname" {
  type        = string
  description = "If the app uses a token host in the app config which redirects to a signon page"
}

variable "workspace_id" {
  type = string
}

##
# Have defaults

# When you need to re-create add the key vault secret key id in, comment after so it doesn't get in
# the way of the plan or you'll need to main after every cert refresh
variable "certificate_kv_secret_id" {
  type        = string
  default     = null
  description = "Used to bind a certificate to the app"
}

variable "log_containers" {
  type    = list(any)
  default = ["app-logs", "web-logs", "db-logs"]
}

variable "scm_use_main_ip_restriction" {
  type    = bool
  default = null
}


##
# locals

locals {
  name = "${var.app}-${var.env}"

  dns_name = "hpa"

  firewall_rules = [
    {
      label = "NOMS Studio office"
      start = var.ips["office"]
      end   = var.ips["office"]
    },
    {
      label = "MOJ Digital"
      start = var.ips["mojvpn"]
      end   = var.ips["mojvpn"]
    }
  ]

  ip_restriction_addresses = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["quantum_alt"]}/32",
    "35.177.252.195/32",
    "${var.ips["mojvpn"]}/32",
    "157.203.176.138/31",
    "157.203.176.140/32",
    "157.203.177.190/31",
    "157.203.177.192/32",
    "62.25.109.201/32",
    "62.25.109.203/32",
    "212.137.36.233/32",
    "212.137.36.234/32",
    "195.59.75.0/24",
    "194.33.192.0/25",
    "194.33.193.0/25",
    "194.33.196.0/25",
    "194.33.197.0/25",
    "195.92.38.20/32", # dxc_webproxy1
    "195.92.38.21/32", # dxc_webproxy2
    "195.92.38.22/32", # dxc_webproxy3
    "195.92.38.23/32", # dxc_webproxy4
    "51.149.250.0/24", # pttp access
    "${var.ips["studiohosting-live"]}/32"
  ]

  tags = {
    Service     = var.app
    Environment = var.env
  }
}
