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
    Service     = var.app
    Environment = var.env
  }
}
variable "tags" {
  type = map
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


variable "sampling_percentage" {
  type        = string
  description = "Fixed rate samping for app insights for reduing volume of telemetry"
}
variable "custom_hostname" {
  type        = string
  description = "custom hostname for the app service"
}
variable "has_database" {
  type        = bool
  description = "If the app service creates a sql server and DB with the app service"
}
variable "sc_branch" {
  type    = string
}
variable "repo_url" {
  type    = string
}

#variable "default_documents" {
#  type = list(string)
#  description = "default documents for the app site config"
#}
