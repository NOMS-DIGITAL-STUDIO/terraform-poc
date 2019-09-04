variable "app-name" {
  type    = "string"
  default = "notm-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "NOTM"
    Environment = "Dev"
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
  api_base_endpoint           = "https://gateway.t3.nomis-api.hmpps.dsd.io"
  api_endpoint_url            = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url          = "${local.api_base_endpoint}/auth/"
  keyworker_api_url           = "https://keyworker-api-dev.hmpps.dsd.io/"
  casenotes_api_url           = "https://dev.offender-case-notes.service.justice.gov.uk"
  categorisation_ui_url       = "https://dev.offender-categorisation.service.justice.gov.uk/"
  nn_endpoint_url             = "https://notm-dev.hmpps.dsd.io/"
  omic_ui_url                 = "https://dev.manage-key-workers.service.justice.gov.uk/"
  whereabouts_ui_url          = "https://prisonstaffhub-dev.hmpps.dsd.io/whereaboutssearch"
  establishment_rollcheck_url = "https://prisonstaffhub-dev.hmpps.dsd.io/establishmentroll"
  prison_staff_hub_ui_url     = "https://prisonstaffhub-dev.hmpps.dsd.io/"
  api_client_id               = "elite2apiclient"
  hmpps_cookie_name           = "hmpps-session-dev"
  hmpps_cookie_domain         = "hmpps.dsd.io"
  remote_auth_strategy        = "true"
  session_timeout_mins        = "60"
}

# TODO: Required? Azure config
locals {
  azurerm_resource_group = "notm-dev"
  azure_region           = "ukwest"
}

# Allow any CIDR to access service
locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
