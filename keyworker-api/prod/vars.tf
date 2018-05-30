variable "app-name" {
  type    = "string"
  default = "keyworker-api-prod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Prod"
  }
}

locals {
  elite2_uri_root        = "https://gateway.nomis-api.service.justice.gov.uk/elite2api"
  omic_clientid          = "omicadmin"
  server_timeout         = "180000"
  azurerm_resource_group = "keyworker-api-prod"
  azure_region           = "ukwest"
  deallocation_job_cron = "0 0 * ? * *"
}
