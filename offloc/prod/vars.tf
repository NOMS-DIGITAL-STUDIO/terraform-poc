variable "app" {
  type    = string
  default = "offloc"
}

variable "env" {
  type    = string
  default = "prod"
}

variable "deployment-channels" {
  type    = list
  default = ["offloc-replacement", "shef_changes"]
}

locals {
  name    = "${var.app}-${var.env}"
  storage = "${var.app}${var.env}storage"
  cname   = var.app

  github_deploy_branch = ""

  extra_dns_zone = "offloc.service.justice.gov.uk"

  app_team_oid = local.azure_empty_group_oid

  app_size  = "S2"
  app_count = 2

  tags = {
    Service     = var.app
    Environment = var.env
  }
}
