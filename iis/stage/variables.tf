variable "app" {
  type = string
}

variable "env" {
  type = string
}
locals {
  name    = "${var.app}-${var.env}"
  storage = "${var.app}${var.env}storage"
  cname   = local.name

  github_deploy_branch = "deploy-to-${var.env}"

  extra_dns_zone = "${var.app}-${var.env}-zone.hmpps.dsd.io"

  app_size  = "S1"
  app_count = 1
  tags = {
    "application"      = "HPA"
    "environment_name" = "prod"
    "service"          = "Misc"
  }

}
#When you need to re-create add the key vault secret key id in, comment after so it doesn't get in the way of the plan or you'll need to main after every cert refresh
variable "certificate_kv_secret_id" {
  type        = string
  default     = null
  description = "Used to bind a certificate to the app"
}

variable "certificate_name" {
  type = string
}

variable "https_only" {
  type    = bool
  default = null
}

variable "app_service_plan_size" {
  type    = string
  default = "B1"
}
variable "ip_restriction_addresses" {
  type = list(string)
}

variable "sampling_percentage" {
  type        = string
  description = "Fixed rate samping for app insights for reduing volume of telemetry"
}
variable "custom_hostname" {
  type        = string
  description = "custom hostname for the app service"
}
variable "has_storage" {
  type        = bool
  description = "If the app service creates a sql server and DB with the app service"
}
variable "log_containers" {
  type    = list(any)
  default = ["app-logs", "web-logs", "db-logs"]
}
variable "sc_branch" {
  type = string
}
variable "repo_url" {
  type = string
}
variable "signon_hostname" {
  type        = string
  description = "If the app uses a token host in the app config which redirects to a signon page"
}

#variable "default_documents" {
#  type = list(string)
#  description = "default documents for the app site config"
#}
