
# TODO note which are for app module

app = "iis"
env = "preprod"
# set below if creating binding from scratch
#certificate_kv_secret_id=""

always_on             = false
app_service_plan_size = "B1"
certificate_name      = "iis-preprod-iis-preprod-CERThpa-preprodDOTserviceDOThmppsDOTdsdDOTio"
create_cname          = true
create_sql_firewall   = true
custom_hostname       = "hpa-preprod.service.hmpps.dsd.io"
default_documents     = ["Default.htm", "Default.html", "Default.asp", "index.htm", "index.html", "iisstart.htm", "default.aspx", "index.php", "hostingstart.html"]
has_storage           = true
https_only            = true
key_vault_secrets     = [
  "signon-client-id",
  "signon-client-secret",
  "administrators"
]
repo_url                    = "https://github.com/ministryofjustice/iis.git"
sampling_percentage         = "100"
sc_branch                   = "deploy-to-preprod"
scm_use_main_ip_restriction = true
signon_hostname             = "https://signon.service.justice.gov.uk"
setup_queries = [
  "IF SCHEMA_ID('HPA') IS NULL EXEC sp_executesql \"CREATE SCHEMA HPA\"",
  "GRANT SELECT ON SCHEMA::HPA TO iisuser",
  "GRANT SELECT ON SCHEMA::IIS TO iisuser",
  "GRANT SELECT, INSERT, DELETE ON SCHEMA::NON_IIS TO iisuser",
  "ALTER ROLE db_datareader ADD MEMBER atodd",
  "ALTER ROLE db_datawriter ADD MEMBER atodd",
  "ALTER ROLE db_ddladmin ADD MEMBER atodd",
  "GRANT SHOWPLAN to atodd",
  "ALTER ROLE db_datareader ADD MEMBER mwhitfield",
  "ALTER ROLE db_datawriter ADD MEMBER mwhitfield",
  "ALTER ROLE db_ddladmin ADD MEMBER mwhitfield",
  "GRANT SHOWPLAN to mwhitfield",
  "ALTER ROLE db_datareader ADD MEMBER sgandalwar",
  "ALTER ROLE db_datawriter ADD MEMBER sgandalwar",
  "ALTER ROLE db_ddladmin ADD MEMBER sgandalwar",
  "GRANT SHOWPLAN to sgandalwar",
]
sql_collation = "Latin1_General_CS_AS"
sql_edition   = "Standard"
sql_scale     = "S3"
sql_space_gb  = 250
sql_users     = [
  "iisuser",
  "mwhitfield",
  "sgandalwar",
  "atodd"
]
tags          = {
  application      = "HPA"                                                    # Mandatory
  business_unit    = "HMPPS"                                                  # Mandatory
  is_production    = "true"                                                   # Mandatory
  owner            = "Malcolm Casimir:malcolm.casimir@digital.justice.gov.uk" # Mandatory
  environment_name = "preprod"
  service          = "Misc"
  source_code      = "infra=https://github.com/ministryofjustice/digital-studio-infra/tree/master/iis/preprod"
}
use_32_bit_worker_process = true