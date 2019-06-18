variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-preprod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub"
    Environment = "PreProd"
  }
}

# App settings
locals {
  api_base_endpoint              = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io"
  api_endpoint_url               = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url             = "${local.api_base_endpoint}/auth/"
  api_client_id                  = "elite2apiclient"
  api_system_client_id           = "prisonstaffhubclient"
  keyworker_api_url              = "https://keyworker-api-preprod.service.hmpps.dsd.io/"
  nn_endpoint_url                = "https://notm-preprod.service.hmpps.dsd.io/"
  licences_endpoint_url          = "https://licences-preprod.service.hmpps.dsd.io/"
  prison_staff_hub_ui_url        = "https://prisonstaffhub-preprod.service.hmpps.dsd.io/"
  api_whereabouts_endpoint_url   = "https://whereabouts-api-preprod.service.justice.gov.uk/"
  hmpps_cookie_name              = "hmpps-session-preprod"
  google_analytics_id            = ""
  remote_auth_strategy           = "true"
  update_attendance_prisons      = ""
  attendance_detail_link_enabled = "true"
  iep_change_link_enabled        = "true"
}

# Instance and Deployment settings
locals {
  instances     = "3"
  mininstances  = "2"
  instance_size = "t2.medium"
}

# Azure config
locals {
  azurerm_resource_group = "prisonstaffhub-preprod"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["quantum_alt"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
  ]
}
