#### VPC (NETWORKING) CONFIGURATION ####
resource "aws_vpc" "monitoring_vpc" {
  cidr_block           = local.default_vpc_ip_range
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.default_resource_name_root}-vpc"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }
}

resource "aws_subnet" "monitoring_public_subnet" {
  vpc_id            = aws_vpc.monitoring_vpc.id
  cidr_block        = local.default_subnet_ip_range
  availability_zone = local.default_availability_zone

  tags = {
    Name = "${local.default_resource_name_root}-subnet"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }

  depends_on = [aws_internet_gateway.monitoring_igw]
}

#### VPC (SECURITY) CONFIGURATION ####

resource "aws_network_acl" "monitoring_default_nacl" {
    vpc_id = aws_vpc.monitoring_vpc.id
    subnet_ids = [aws_subnet.monitoring_public_subnet.id]

    tags = {
      Name = "${local.default_resource_name_root}-default-nacl"
      Environment = local.default_environment_name
      Application = local.default_application_name
      Owner = "DSO"
    }
}

resource "aws_network_acl_rule" "monitoring_nacl_rule_https_all_in" {
    network_acl_id = aws_network_acl.monitoring_default_nacl.id
    rule_number    = 260
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = "443"
    to_port        = "443"
}


resource "aws_network_acl_rule" "monitoring_nacl_rule_all_unpriv_in" {
    network_acl_id = aws_network_acl.monitoring_default_nacl.id
    rule_number    = 270
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = "0.0.0.0/0"
    from_port      = "1024"
    to_port        = "65535"
}

resource "aws_network_acl_rule" "monitoring_default_nacl_ssh_in" {
    network_acl_id = aws_network_acl.monitoring_default_nacl.id
    rule_number    = 220
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = local.allowed_inbound_ip
    from_port      = "22"
    to_port        = "22"
}

resource "aws_network_acl_rule" "monitoring_default_nacl_ssh_vpn_in" {
    network_acl_id = aws_network_acl.monitoring_default_nacl.id
    rule_number    = 230
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = local.allowed_inbound_vpn_ip
    from_port      = "22"
    to_port        = "22"
}

resource "aws_network_acl_rule" "monitoring_default_nacl_grafana_in" {
    network_acl_id = aws_network_acl.monitoring_default_nacl.id
    rule_number    = 240
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = local.allowed_inbound_ip
    from_port      = "3000"
    to_port        = "3000"
}

resource "aws_network_acl_rule" "monitoring_default_nacl_grafana_vpn_in" {
    network_acl_id = aws_network_acl.monitoring_default_nacl.id
    rule_number    = 250
    egress         = false
    protocol       = "tcp"
    rule_action    = "allow"
    cidr_block     = local.allowed_inbound_vpn_ip
    from_port      = "3000"
    to_port        = "3000"
}

resource "aws_network_acl_rule" "monitoring_nacl_rule_all_out" {
    network_acl_id = aws_network_acl.monitoring_default_nacl.id
    rule_number    = 200
    egress         = true
    protocol       = "-1"
    rule_action    = "allow"
    cidr_block     = "0.0.0.0/0"
}

resource "aws_internet_gateway" "monitoring_igw" {
  vpc_id = aws_vpc.monitoring_vpc.id

  tags = {
    Name = "${local.default_resource_name_root}-igw"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }
}

resource "aws_default_route_table" "default_monitoring_rt" {
  default_route_table_id = aws_vpc.monitoring_vpc.default_route_table_id

  tags = {
    Name = "${local.default_resource_name_root}-default-rt"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.monitoring_igw.id
  }
}

resource "aws_route_table_association" "monitoring_rt_assoc" {
  subnet_id      = aws_subnet.monitoring_public_subnet.id
  route_table_id = aws_default_route_table.default_monitoring_rt.id
}

resource "aws_security_group" "monitoring_ec2_sg" {
  name        = "${local.default_environment_name}-monitoring-sg"
  vpc_id      = aws_vpc.monitoring_vpc.id

  tags = {
    Name = "${local.default_resource_name_root}-default-sg"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }
}

resource "aws_security_group_rule" "monitoring_sgrule_allow_all_out" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.monitoring_ec2_sg.id
}

resource "aws_security_group_rule" "monitoring_sgrule_grafana_in" {
  type            = "ingress"
  from_port       = 3000
  to_port         = 3000
  protocol        = "tcp"
  cidr_blocks     = [local.allowed_inbound_ip]
  security_group_id = aws_security_group.monitoring_ec2_sg.id
}

resource "aws_security_group_rule" "monitoring_sgrule_grafana_vpn_in" {
  type            = "ingress"
  from_port       = 3000
  to_port         = 3000
  protocol        = "tcp"
  cidr_blocks     = [local.allowed_inbound_vpn_ip]
  security_group_id = aws_security_group.monitoring_ec2_sg.id
}

resource "aws_security_group_rule" "monitoring_sgrule_https_in" {
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.monitoring_ec2_sg.id
}

resource "aws_security_group_rule" "monitoring_sgrule_ssh_in" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = [local.allowed_inbound_ip]
  security_group_id = aws_security_group.monitoring_ec2_sg.id
}

resource "aws_security_group_rule" "monitoring_sgrule_ssh_vpn_in" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = [local.allowed_inbound_vpn_ip]
  security_group_id = aws_security_group.monitoring_ec2_sg.id
}

###### IAM CONFIGURATION ######

data "aws_iam_policy_document" "monitoring_iam_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring_iam_role" {
  name               = "${local.default_iam_resource_name_root}-role"
  assume_role_policy = data.aws_iam_policy_document.monitoring_iam_assume_role_policy.json

  tags = {
    Name = "${local.default_iam_resource_name_root}-role"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }
}

resource "aws_iam_policy" "monitoring_iam_policy" {
  name = "${local.default_iam_resource_name_root}-policy"
  description = "Default policy for IAM access to CloudWatch"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:GetMetricData",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "monitoring_iam_policy_attachment" {
  name       = "${local.default_iam_resource_name_root}-policy-attachment"
  users      = [aws_iam_user.monitoring_iam_user.name]
  roles      = [aws_iam_role.monitoring_iam_role.name]
  policy_arn = aws_iam_policy.monitoring_iam_policy.arn
}

resource "aws_iam_instance_profile" "monitoring_iam_instance_profile" {
  name = "${local.default_iam_resource_name_root}-instance-profile"
  role = aws_iam_role.monitoring_iam_role.name
}
resource "aws_iam_user" "monitoring_iam_user" {
  name = "${local.default_iam_resource_name_root}-user"
  path = "/system/"

  tags = {
    Name = "${local.default_iam_resource_name_root}-user"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }
}

resource "aws_iam_access_key" "monitoring_iam_access_key" {
  user    = aws_iam_user.monitoring_iam_user.name
}

##### EC2 CONFIGURATION #####

data "aws_ami" "monitoring_ec2_default_ami" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
      name   = "name"
      values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}

data "template_file" "monitoring_ec2_instance_user_data" {
  template = file("${path.module}/ec2_instance_user_data.tpl")
}

resource "aws_instance" "monitoring_ec2_instance" {
  ami                  = data.aws_ami.monitoring_ec2_default_ami.id
  instance_type        = local.default_ec2_instance_size
  availability_zone    = local.default_availability_zone
  ebs_optimized        = false
  iam_instance_profile = aws_iam_instance_profile.monitoring_iam_instance_profile.name
  key_name             = local.default_ec2_instance_key_pair
  user_data = data.template_file.monitoring_ec2_instance_user_data.rendered

  tags = {
    Name = local.default_resource_name_root
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }

  network_interface {
    network_interface_id = aws_network_interface.monitoring_ec2_nic.id
    device_index         = 0
  }
}

#### INSTANCE NETWORKING ####

resource "aws_network_interface" "monitoring_ec2_nic" {
  subnet_id       = aws_subnet.monitoring_public_subnet.id
  private_ips     = local.default_ec2_instance_private_ips
  security_groups = [aws_security_group.monitoring_ec2_sg.id]

  tags = {
    Name = "${local.default_resource_name_root}-nic"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }

  depends_on = [aws_subnet.monitoring_public_subnet]
}

resource "aws_eip" "monitoring_eip" {
  instance = aws_instance.monitoring_ec2_instance.id
  vpc      = true

  tags = {
    Name = "${local.default_resource_name_root}-eip"
    Environment = local.default_environment_name
    Application = local.default_application_name
    Owner = "DSO"
  }
}

#### DOMAIN NAME RESOLUTION ####

resource "azurerm_dns_a_record" "monitoring_dns_a_record" {
  name                = "dso-${local.default_application_name}-${local.default_environment_name}"
  zone_name           = local.default_dns_zone
  resource_group_name = local.default_dns_resource_group
  ttl                 = 300
  records             = [aws_eip.monitoring_eip.public_ip]

  depends_on = [aws_eip.monitoring_eip]
}

resource "azurerm_dns_cname_record" "monitoring_dns_cname_record" {
  name                = "dso-${local.default_application_name}-${local.default_environment_name}"
  zone_name           = local.default_dns_zone
  resource_group_name = local.default_dns_resource_group
  ttl                 = 300
  record             = aws_instance.monitoring_ec2_instance.public_dns

  depends_on = [aws_instance.monitoring_ec2_instance]
}
