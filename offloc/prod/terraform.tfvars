tags = { "application" = "NonCore"
  "environment_name" = "prod"
  "service"          = "NonCore"
}
app = "offloc"
env = "prod"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
certificate_name      = "offloc-prod-offloc-prod-CERTwwwDOTofflocDOTserviceDOTjusticeDOTgovDOTuk"
https_only            = true
sampling_percentage   = "0"
custom_hostname       = "www.offloc.service.justice.gov.uk"
has_storage           = true
app_service_plan_size = "S2"
