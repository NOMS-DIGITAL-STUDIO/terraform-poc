
resource "aws_security_group" "internalec2" {
  name        = "${var.app-name}-internalec2"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "elasticbeanstalk EC2 internal instances"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.internalelb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "${var.app-name}-internalec2"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "internalelb" {
  name        = "${var.app-name}-internalelb"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Internal ELB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.ec2.id}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.private-a.cidr_block}","${aws_subnet.private-b.cidr_block}"]
  }

  tags = "${merge(map("Name", "${var.app-name}-internalelb"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elastic_beanstalk_application" "pdf-gen-app" {
  name        = "licences-pdf-generator"
  description = "licences-pdf-generator"
}


resource "aws_elastic_beanstalk_environment" "pdf-gen-app-env" {
  name                = "${var.pdf-gen-app-name}"
  application         = "${aws_elastic_beanstalk_application.pdf-gen-app.name}"
  solution_stack_name = "${data.aws_elastic_beanstalk_solution_stack.docker.name}"
  tier                = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${aws_security_group.internalec2.id}"
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
    value     = "${aws_security_group.internalelb.id}"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.internalelb.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${aws_vpc.vpc.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internal"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private-a.id},${aws_subnet.private-b.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.private-a.id},${aws_subnet.private-b.id}"
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

  # Begin app-specific config settings
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APPINSIGHTS_INSTRUMENTATIONKEY"
    value     = "${data.aws_ssm_parameter.appinsights_instrumentationkey.value}"
  }

  tags = "${var.pdf-gen-tags}"
}
