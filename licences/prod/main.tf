# This resource is managed in multiple places (licences mock)
resource "aws_elastic_beanstalk_application" "app" {
  name        = "licences"
  description = "licences"
}

resource "random_id" "session-secret" {
  byte_length = 40
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
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckInterval"
    value     = "30"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthyThresholdCount"
    value     = "2"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "UnhealthyThresholdCount"
    value     = "3"
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
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Enabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Prefix"
    value     = "${var.app-name}"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Bucket"
    value     = "dps-elasticbeanstalk-access-logs-prod"
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
    value     = "${local.mininstances}"
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

  setting {
    namespace = "aws:elasticbeanstalk:environment:proxy"
    name      = "ProxyServer"
    value     = "none"
  }

  # Begin app-specific config settings
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DOMAIN"
    value     = "${local.domain}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENABLE_TEST_UTILS"
    value     = "false"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NOMIS_API_URL"
    value     = "${local.nomis_api_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NOMIS_AUTH_URL"
    value     = "${local.nomis_auth_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "GLOBAL_SEARCH_URL"
    value     = "${local.global_search_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME"
    value     = "${aws_db_instance.db.name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_SERVER"
    value     = "${replace(aws_db_instance.db.endpoint, ":5432", "")}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USER"
    value     = "${aws_db_instance.db.username}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASS"
    value     = "${aws_db_instance.db.password}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APPINSIGHTS_INSTRUMENTATIONKEY"
    value     = "${data.aws_ssm_parameter.appinsights_instrumentationkey.value}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SESSION_SECRET"
    value     = "${random_id.session-secret.b64}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_CLIENT_SECRET"
    value     = "${data.aws_ssm_parameter.api-client-secret.value}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ADMIN_API_CLIENT_SECRET"
    value     = "${data.aws_ssm_parameter.admin-api-client-secret.value}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "TAG_MANAGER_KEY"
    value     = "${data.aws_ssm_parameter.tag-manager-api-client-secret.value}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AUTH_STRATEGY"
    value     = "${local.authStrategy}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NOTIFY_API_KEY"
    value     = "${data.aws_ssm_parameter.notify-api-client-secret.value}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PUSH_TO_NOMIS"
    value     = "${local.pushToNomis}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REMINDERS_SCHEDULE_RO"
    value     = "${local.remindersScheduleRo}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SCHEDULED_JOBS_AUTOSTART"
    value     = "${local.scheduledJobAuto}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SCHEDULED_JOBS_OVERLAP"
    value     = "${local.scheduledJobOverlap}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NOTIFY_ACTIVE_TEMPLATES"
    value     = "${local.notifyActiveTemplates}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RO_SERVICE_TYPE"
    value     = "${local.roServiceType}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DELIUS_API_URL"
    value     = "${local.deliusApiUrl}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CLEARING_OFFICE_EMAIL"
    value     = "${local.clearingOfficeEmail}"
  }
  tags = "${var.tags}"
}

# Because Elastic Beanstalk does not yet support configuring a redirect action
# we have to do it this way.  Find the arn of the ALB and listener, and
# then setup the listener rule:
data "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_elastic_beanstalk_environment.app-env.load_balancers[0]}"
  port = 80
}

resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = "${data.aws_lb_listener.listener.arn}"

  action {
   type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    field  = "path-pattern"
    values = ["/*"]
  }
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

resource "azurerm_dns_cname_record" "acm-verify" {
  name                = "${substr(local.aws_record_name, 0, length(local.aws_record_name)-2)}"
  zone_name           = "${local.azure_dns_zone_name}"
  resource_group_name = "${local.azure_dns_zone_rg}"
  ttl                 = "300"
  record              = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"
}
