tags = {
  application      = "NonCore"                                                # Mandatory
  business_unit    = "HMPPS"                                                  # Mandatory
  is_production    = "false"                                                  # Mandatory
  owner            = "Malcolm Casimir:malcolm.casimir@digital.justice.gov.uk" # Mandatory
  environment_name = "devtest"
  service          = "NonCore"
  source_code      = "infra=https://github.com/ministryofjustice/digital-studio-infra/tree/master/offloc/stage"
}
app = "offloc"
env = "stage"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
certificate_name    = "offloc-stage-offloc-stage-CERTwwwDOToffloc-stage-zoneDOThmppsDOTdsdDOTio"
https_only          = true
sampling_percentage = "100"
custom_hostname     = "offloc-stage.hmpps.dsd.io"
has_storage         = true
sc_branch           = "deploy-to-stage"
repo_url            = "https://github.com/ministryofjustice/offloc-server.git"
workspace_id = "/subscriptions/b1f3cebb-4988-4ff9-9259-f02ad7744fcb/resourceGroups/noms-test-loganalytics/providers/Microsoft.OperationalInsights/workspaces/noms-test"
