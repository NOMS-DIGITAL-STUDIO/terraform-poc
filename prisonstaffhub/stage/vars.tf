variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-stage"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub"
    Environment = "Stage"
  }
}

# App settings
locals {
  api_base_endpoint              = "https://gateway.t2.nomis-api.hmpps.dsd.io"
  api_endpoint_url               = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url             = "${local.api_base_endpoint}/auth/"
  api_client_id                  = "elite2apiclient"
  api_system_client_id           = "prisonstaffhubclient"
  keyworker_api_url              = "https://keyworker-api-stage.hmpps.dsd.io/"
  nn_endpoint_url                = "https://notm-stage.hmpps.dsd.io/"
  licences_endpoint_url          = "https://licences-stage.hmpps.dsd.io/"
  prison_staff_hub_ui_url        = "https://prisonstaffhub-stage.hmpps.dsd.io/"
  api_whereabouts_endpoint_url   = "https://whereabouts-api-dev.service.justice.gov.uk/"
  hmpps_cookie_name              = "hmpps-session-stage"
  google_analytics_id            = ""
  remote_auth_strategy           = "true"
  update_attendance_prisons      = ""
  attendance_detail_link_enabled = "false"
  iep_change_link_enabled        = "false"
}

# Instance and Deployment settings
locals {
  instances     = "2"
  mininstances  = "1"
  instance_size = "t2.micro"
}

# Azure config
locals {
  azurerm_resource_group = "prisonstaffhub-stage"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
