tags = {
  application      = "NonCore"                                                # Mandatory
  business_unit    = "HMPPS"                                                  # Mandatory
  is_production    = "true"                                                   # Mandatory
  owner            = "Malcolm Casimir:malcolm.casimir@digital.justice.gov.uk" # Mandatory
  environment_name = "prod"
  service          = "NonCore"
  source_code      = "infra=https://github.com/ministryofjustice/digital-studio-infra/tree/master/offloc/prod"
}
app = "offloc"
env = "prod"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
certificate_name = "offloc-prod-offloc-prod-CERTwwwDOTofflocDOTserviceDOTjusticeDOTgovDOTuk"
default_documents = [
  "Default.htm",
  "Default.html",
  "Default.asp",
  "index.htm",
  "index.html",
  "iisstart.htm",
  "default.aspx",
  "index.php",
  "hostingstart.html",
]
https_only            = true
sampling_percentage   = "0"
custom_hostname       = "www.offloc.service.justice.gov.uk"
has_storage           = true
app_service_plan_size = "S2"
workspace_id          = "/subscriptions/1d95dcda-65b2-4273-81df-eb979c6b547b/resourceGroups/noms-prod-loganalytics/providers/Microsoft.OperationalInsights/workspaces/noms-prod1"
