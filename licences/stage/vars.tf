variable "app-name" {
  type    = "string"
  default = "licences-stage"
}

variable "tags" {
  type = "map"

  default {
    Service     = "Licences"
    Environment = "Stage"
  }
}

# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
  db_multi_az = "false"
  db_backup_retention_period = "0"
  db_maintenance_window = "Mon:00:00-Sun:11:59"
  db_apply_immediately = "true"
}

# App settings
locals {
  nomis_api_url       = "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api"
  nomis_auth_url      = "https://gateway.t3.nomis-api.hmpps.dsd.io/auth"
  api_client_id       = "licences"
  domain              = "https://licences-stage.hmpps.dsd.io"
  authStrategy        = "oauth"
  global_search_url   = "https://prisonstaffhub-dev.hmpps.dsd.io/global-search"
  pushToNomis         = "yes"
  remindersScheduleRo = "0 1 * * 1-5"
  scheduledJobAuto    = "no"
  scheduledJobOverlap = "5000"
  notifyActiveTemplates = "CA_RETURN,CA_DECISION,RO_NEW,RO_TWO_DAYS,RO_DUE,RO_OVERDUE,DM_NEW,DM_TO_CA_RETURN"
  roServiceType       = "DELIUS"
  deliusApiUrl        = "https://community-api-t2.hmpps.dsd.io/communityapi/api"
  clearingOfficeEmail = "hdc_test+co@digital.justice.gov.uk"
}

# Azure config
locals {
  azurerm_resource_group = "licences-stage"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
