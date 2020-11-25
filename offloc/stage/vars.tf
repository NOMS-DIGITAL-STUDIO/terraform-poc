variable "app" {
  type    = string
  default = "offloc"
}

variable "env" {
  type    = string
  default = "stage"
}

variable "deployment-channels" {
  type    = list
  default = ["offloc-replacement"]
}

locals {
  name    = "${var.app}-${var.env}"
  storage = "${var.app}${var.env}storage"
  cname   = local.name

  github_deploy_branch = "deploy-to-${var.env}"

  extra_dns_zone = "${var.app}-${var.env}-zone.hmpps.dsd.io"

  app_team_oid = local.azure_offloc_group_oid

  app_size  = "S1"
  app_count = 1

  tags = {
    Service     = var.app
    Environment = var.env
  }
}
