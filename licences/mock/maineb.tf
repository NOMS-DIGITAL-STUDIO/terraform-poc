variable "app-name" {
  type    = "string"
  default = "licences-mock"
}

# This resource is managed in multiple places (licences stage)
resource "aws_elastic_beanstalk_application" "app" {
  name        = "licences"
  description = "licences"
}

//data "aws_acm_certificate" "cert" {
//  domain = "${var.app-name}.hmpps.dsd.io"
//}

resource "aws_security_group" "elb" {
  name        = "${var.app-name}-elb"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "ELB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  name_regex  = "^64bit Amazon Linux .* v2.* running Docker 17.*$"
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
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
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
    value     = "classic"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "ManagedSecurityGroup"
    value     = "${aws_security_group.elb.id}"
  }

  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.elb.id}"
  }

//  setting {
//    namespace = "aws:elb:listener:443"
//    name      = "ListenerProtocol"
//    value     = "HTTPS"
//  }

//  setting {
//    namespace = "aws:elb:listener:443"
//    name      = "SSLCertificateId"
//    value     = "${data.aws_acm_certificate.cert.arn}"
//  }

//  setting {
//    namespace = "aws:elb:listener:443"
//    name      = "InstancePort"
//    value     = "80"
//  }
//
//  setting {
//    namespace = "aws:elb:listener:443"
//    name      = "ListenerProtocol"
//    value     = "HTTPS"
//  }

//  setting {
//    namespace = "aws:elb:policies:tlshigh"
//    name      = "LoadBalancerPorts"
//    value     = "443"
//  }

  setting {
    namespace = "aws:elb:policies:tlshigh"
    name      = "SSLReferencePolicy"
    value     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${aws_vpc.vpc.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private-a.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public-a.id}"
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

  # Begin app-specific config settings
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APPINSIGHTS_INSTRUMENTATIONKEY"
    value     = "${azurerm_template_deployment.insights.outputs["instrumentationKey"]}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_GATEWAY_ENABLED"
    value     = "false"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENABLE_TEST_UTILS"
    value     = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NOMIS_API_URL"
    value     = "https://licences-nomis-mocks.herokuapp.com/elite2api"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME"
    value     = "${aws_db_instance.db.name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_SERVER"
    value     = "${aws_db_instance.db.endpoint}"
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
    name      = "SESSION_SECRET"
    value     = "${random_id.session-secret.b64}"
  }
  tags = "${var.tags}"
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "${var.app-name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "60"
  record              = "${aws_elastic_beanstalk_environment.app-env.cname}"
}

resource "azurerm_dns_cname_record" "acm-verify" {
  name                = "_7ac2509e32e89c189806d3eccd973161.licences-mock"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "300"
  record              = "_c0f012c76b2277660098f229219a2b02.acm-validations.aws."
}
