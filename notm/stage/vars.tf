variable "app-name" {
  type    = "string"
  default = "notm-stage"
}

variable "tags" {
  type = "map"

  default {
    Service     = "NOTM"
    Environment = "Stage"
  }
}

# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
  instance_size = "t2.micro"
}

# Application-specific settings and properties

locals {
  api_base_endpoint           = "https://gateway.t2.nomis-api.hmpps.dsd.io"
  api_endpoint_url            = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url          = "${local.api_base_endpoint}/auth/"
  keyworker_api_url           = "https://keyworker-api-stage.hmpps.dsd.io/"
  casenotes_api_url           = "${local.api_base_endpoint}/elite2api/"
  categorisation_ui_url       = ""
  nn_endpoint_url             = "https://notm-stage.hmpps.dsd.io/"
  omic_ui_url                 = "https://omic-stage.hmpps.dsd.io/"
  whereabouts_ui_url          = "https://prisonstaffhub-stage.hmpps.dsd.io/whereaboutssearch"
  establishment_rollcheck_url = "https://prisonstaffhub-stage.hmpps.dsd.io/establishmentroll"
  prison_staff_hub_ui_url     = "https://prisonstaffhub-stage.hmpps.dsd.io/"
  api_client_id               = "elite2apiclient"
  hmpps_cookie_name           = "hmpps-session-stage"
  hmpps_cookie_domain         = "hmpps.dsd.io"
  remote_auth_strategy        = "true"
  session_timeout_mins        = "60"
}

# Azure config
locals {
  azurerm_resource_group = "notm-stage"
  azure_region           = "ukwest"
}

# Allow any CIDR to access service
locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
