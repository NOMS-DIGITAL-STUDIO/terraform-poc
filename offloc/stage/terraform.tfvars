tags = { "application" = "NonCore"
  "environment_name" = "devtest"
  "service"          = "NonCore"
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
