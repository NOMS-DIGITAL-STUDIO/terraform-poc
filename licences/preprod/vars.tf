variable "app-name" {
  type    = "string"
  default = "licences-preprod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "Licences"
    Environment = "PreProd"
  }
}

variable "pdf-gen-app-name" {
  type    = "string"
  default = "licences-pdf-generator-preprod"
}

variable "pdf-gen-tags" {
  type = "map"

  default {
    Service     = "licences-pdf-generator"
    Environment = "PreProd"
  }
}


# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
  db_multi_az = "true"
  db_backup_retention_period = "30"
  db_maintenance_window = "Mon:00:00-Sun:11:59"
  db_apply_immediately = "true"
}

# App settings
locals {
  nomis_api_url       = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/elite2api/api"
  api_client_id       = "licences"
  domain              = "https://licences-preprod.hmpps.dsd.io"
}

# Azure config
locals {
  azurerm_resource_group = "licences-preprod"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
  ]
}
