tags = {
  application      = "RSR"                                                       # Mandatory
  business_unit    = "HMPPS"                                                     # Mandatory
  is_production    = "false"                                                     # Mandatory
  owner            = "DSO:digital-studio-operations-team@digital.justice.gov.uk" # Mandatory
  environment_name = "devtest"
  service          = "Misc"
  source_code      = "infra=https://github.com/ministryofjustice/digital-studio-infra/tree/main/rsr/dev"
}
app = "rsr"
env = "dev"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
certificate_name    = "rsr-dev-rsr-dev-CERTrsr-devDOThmppsDOTdsdDOTio"
https_only          = true
sampling_percentage = "100"
custom_hostname     = "rsr-dev.hmpps.dsd.io"
workspace_id        = "/subscriptions/b1f3cebb-4988-4ff9-9259-f02ad7744fcb/resourceGroups/noms-test-loganalytics/providers/Microsoft.OperationalInsights/workspaces/noms-test"
