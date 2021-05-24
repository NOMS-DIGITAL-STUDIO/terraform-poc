module "app_service" {
  source                       = "../../shared/modules/azure-app-service"
  app                          = var.app
  env                          = var.env
  certificate_name             = var.certificate_name
  https_only                   = true
  http2_enabled                = true
  app_service_kind             = "Windows"
  azure_jenkins_sp_oid         = var.azure_jenkins_sp_oid
  azure_repo_app_principal_oid = var.azure_repo_app_principal_oid
  sampling_percentage          = var.sampling_percentage
  custom_hostname              = var.custom_hostname
  sa_name                      = "${replace(local.name, "-", "")}storage"
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
  workspace_id = var.workspace_id
  tags         = var.tags
}
