module "app_service" {
  source                   = "../../shared/modules/azure-app-service"
  app                      = var.app
  env                      = var.env
  certificate_name         = var.certificate_name
  app_service_kind         = "Windows"
  sc_branch = var.sc_branch
  repo_url = var.repo_url
  
    app_service_plan_size = "S1"
  azure_jenkins_sp_oid     = var.azure_jenkins_sp_oid
  sampling_percentage      = var.sampling_percentage
  custom_hostname          = var.custom_hostname
  has_database             = var.has_database
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
  tags = var.tags
  }
