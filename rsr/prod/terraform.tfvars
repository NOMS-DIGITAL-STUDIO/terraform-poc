tags = {
  application      = "RSR"                                                       # Mandatory
  business_unit    = "HMPPS"                                                     # Mandatory
  is_production    = "true"                                                      # Mandatory
  owner            = "DSO:digital-studio-operations-team@digital.justice.gov.uk" # Mandatory
  environment_name = "prod"
  service          = "Misc"
  source_code      = "infra=https://github.com/ministryofjustice/digital-studio-infra/tree/master/rsr/prod"
}
app              = "rsr"
env              = "prod"
certificate_name = "rsr-prod-rsr-prod-CERTrsrDOTserviceDOThmppsDOTdsdDOTio"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
https_only          = true
sampling_percentage = "50"
custom_hostname     = "rsr.service.hmpps.dsd.io"
sc_branch           = "master"
repo_url            = "https://rsr-prod.scm.azurewebsites.net"
workspace_id = "/subscriptions/1d95dcda-65b2-4273-81df-eb979c6b547b/resourceGroups/noms-prod-loganalytics/providers/Microsoft.OperationalInsights/workspaces/noms-prod1"
