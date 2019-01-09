variable "environment-name" { type = "string" }

variable "key-pair-name" { type = "string" }

# Instance and Deployment settings
locals {
  default_environment_name = "${var.environment-name}"
  default_iam_resource_name_root = "dso-${local.default_environment_name}-cloudwatch"
  default_vpc_ip_range = "192.168.0.0/24"
  default_subnet_ip_range = "192.168.0.0/28"
  allowed_inbound_ip = "217.33.148.210/32"
  default_ec2_instance_size = "t2.small"
  default_ec2_instance_private_ips = ["192.168.0.5"]
  default_ec2_instance_key_pair = "${var.key-pair-name}"
}
