variable "app-name" {
  type    = "string"
  default = "keyworker-api-stage"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Stage"
  }
}

locals {
  elite2_uri_root = "https://gateway.t2.nomis-api.hmpps.dsd.io/elite2api"
  omic_clientid = "omicadmin"
  server_timeout = "180000"
  deallocation_job_cron = "0 0 * ? * *"
}
