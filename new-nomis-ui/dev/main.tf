# This resource is managed in multiple places (all notm environments)
resource "aws_elastic_beanstalk_application" "app" {
  name        = "notm"
  description = "notm"
}

# TODO: required? (this is in OMIC too)
resource "azurerm_resource_group" "group" {
  name     = "${local.azurerm_resource_group}"
  location = "${local.azure_region}"
  tags     = "${var.tags}"
}

# TODO: Required?  (this is in OMIC too)
resource "azurerm_application_insights" "insights" {

  name                = "${var.app-name}"
  location            = "North Europe"
  resource_group_name = "${azurerm_resource_group.group.name}"
  application_type    = "Web"
}

resource "aws_security_group" "elb" {

  name        = "${var.app-name}-elb"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "ELB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${local.allowed-list}"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${local.allowed-list}"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.private-a.cidr_block}","${aws_subnet.private-b.cidr_block}"]
  }

  tags = "${merge(map("Name", "${var.app-name}-elb"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.app-name}-ec2"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "elasticbeanstalk EC2 instances"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "${var.app-name}-ec2"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux .* v2.* running Docker *.*$"
}

resource "aws_elastic_beanstalk_environment" "app-env" {

  name                = "${var.app-name}"
  application         = "${aws_elastic_beanstalk_application.app.name}"
  solution_stack_name = "${data.aws_elastic_beanstalk_solution_stack.docker.name}"
  tier                = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${aws_security_group.ec2.id}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "${local.instance_size}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

 #>>> HEALTH MONITORING

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "ConfigDocument"
    value     = "${file("../../shared/aws_eb_health_config.json")}"
  }

  #<<< HEALTH MONITORING

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "/health"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/health"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "ManagedSecurityGroup"
    value     = "${aws_security_group.elb.id}"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.elb.id}"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = "${aws_acm_certificate.cert.arn}"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLPolicy"
    value     = "${local.elb_ssl_policy}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${aws_vpc.vpc.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private-a.id},${aws_subnet.private-b.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public-a.id},${aws_subnet.public-b.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Fri:10:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "InstanceRefreshEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  # Rolling updates
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "${local.mininstances == "0" ? 1 : local.mininstances}"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "${local.instances + (local.instances == local.mininstances ? 1 : 0)}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "${local.mininstances == "0" ? "false" : "true"}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Health"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MinInstancesInService"
    value     = "${local.mininstances}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "${local.instances == local.mininstances ? "RollingWithAdditionalBatch" : "Rolling"}"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MaxBatchSize"
    value     = "1"
  }

  #
  # Begin app-specific config settings
  #

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_ENDPOINT_URL"
    value     = "${local.api_endpoint_url}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OAUTH_ENDPOINT_URL"
    value     = "${local.oauth_endpoint_url}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "KEYWORKER_API_URL"
    value     = "${local.keyworker_api_url}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NN_ENDPOINT_URL"
    value     = "${local.nn_endpoint_url}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OMIC_UI_URL"
    value     = "${local.omic_ui_url}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PRISON_STAFF_HUB_UI_URL"
    value     = "${local.prison_staff_hub_ui_url}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_CLIENT_ID"
    value     = "${local.api_client_id}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_CLIENT_SECRET"
    value     = "${data.aws_ssm_parameter.api-client-secret.value}"
  }

  # TODO: Azure insights - required?
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APPINSIGHTS_INSTRUMENTATIONKEY"
    value     = "${azurerm_application_insights.insights.instrumentation_key}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "HMPPS_COOKIE_NAME"
    value     = "${local.hmpps_cookie_name}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "HMPPS_COOKIE_DOMAIN"
    value     = "${local.azure_dns_zone_name}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SESSION_COOKIE_SECRET"
    value     = "${data.aws_ssm_parameter.session-cookie-secret.value}"
  }

  # TODO: uestion this !
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }

  # TODO: What is the correct value for this?
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "GOOGLE_ANALYTICS_ID"
    value     = "${local.google_analytics_id}"
  }

  # Checked
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "GOOGLE_TAG_MANAGER_ID"
    value     = "${local.google_tag_manager_id}"
  }

  # Checke
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REMOTE_AUTH_STRATEGY"
    value     = "${local.remote_auth_strategy}"
  }

  tags = "${var.tags}"
}

locals {
  cname = "${replace(var.app-name,"-prod","")}"
}

# Allow AWS's ACM to manage the apps FQDN

resource "aws_acm_certificate" "cert" {
  domain_name       = "${local.cname}.${local.azure_dns_zone_name}"
  validation_method = "DNS"
  tags              = "${var.tags}"
}

# Azure - required?
resource "azurerm_dns_cname_record" "cname" {
  name                = "${local.cname}"
  zone_name           = "${local.azure_dns_zone_name}"
  resource_group_name = "${local.azure_dns_zone_rg}"
  ttl                 = "60"
  record              = "${aws_elastic_beanstalk_environment.app-env.cname}"
}

locals {
  aws_record_name = "${replace(aws_acm_certificate.cert.domain_validation_options.0.resource_record_name,local.azure_dns_zone_name,"")}"
}

# Azure - required?
resource "azurerm_dns_cname_record" "acm-verify" {
  name                = "${substr(local.aws_record_name, 0, length(local.aws_record_name)-2)}"
  zone_name           = "${local.azure_dns_zone_name}"
  resource_group_name = "${local.azure_dns_zone_rg}"
  ttl                 = "300"
  record              = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"
}
