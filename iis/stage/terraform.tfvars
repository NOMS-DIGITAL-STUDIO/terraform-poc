app = "iis"
env = "stage"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
always_on             = false
app_service_plan_size = "B1"
certificate_name      = "iis-stage-iis-stage-CERThpa-stageDOThmppsDOTdsdDOTio"
create_cname          = false
create_sql_firewall   = false
custom_hostname       = "hpa-stage.hmpps.dsd.io"
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
has_storage = true
https_only  = true
key_vault_secrets = [
  "signon-client-id",
  "signon-client-secret",
  "administrators"
]
repo_url                    = "https://github.com/ministryofjustice/iis"
sampling_percentage         = "100"
sc_branch                   = "azure"
scm_use_main_ip_restriction = false
setup_queries               = []
signon_hostname             = "https://www.signon.dsd.io"
sql_collation               = "SQL_Latin1_General_CP1_CI_AS"
sql_edition                 = "Basic"
sql_scale                   = "Basic"
sql_space_gb                = 2
sql_users = [
  "iisuser"
]
tags = {
  application      = "HPA"                                                    # Mandatory
  business_unit    = "HMPPS"                                                  # Mandatory
  is_production    = "false"                                                  # Mandatory
  owner            = "Malcolm Casimir:malcolm.casimir@digital.justice.gov.uk" # Mandatory
  environment_name = "devtest"
  service          = "Misc"
  source_code      = "https://github.com/ministryofjustice/digital-studio-infra/tree/master/iis/stage"
}
use_32_bit_worker_process = true