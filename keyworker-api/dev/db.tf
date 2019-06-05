resource "aws_db_subnet_group" "db" {
  name       = "${var.app-name}-db"
  subnet_ids = ["${aws_subnet.db-a.id}", "${aws_subnet.db-b.id}"]

  tags = "${merge(map("Name", "${var.app-name}-db"), var.tags)}"
}

resource "aws_security_group" "db" {
  name        = "${var.app-name}-db-sg"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "${var.app-name} DB security group"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks     = ["${var.ips["office"]}/32", "${var.ips["mojvpn"]}/32"]
    security_groups = ["${aws_security_group.ec2.id}"]
  }

  tags = "${merge(map("Name", "${var.app-name}-db"), var.tags)}"
}

resource "random_id" "db-password" {
  byte_length = 16
}

resource "aws_db_parameter_group" "db" {
  name   = "${var.app-name}"
  family = "postgres10"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_instance" "db" {
  identifier                = "${var.app-name}"
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "postgres"
  engine_version            = "10.6"
  parameter_group_name      = "${aws_db_parameter_group.db.name}"
  instance_class            = "db.t2.small"
  name                      = "${replace(var.app-name, "-", "_")}"
  username                  = "keyworker"
  password                  = "${random_id.db-password.b64}"
  db_subnet_group_name      = "${aws_db_subnet_group.db.name}"
  vpc_security_group_ids    = ["${aws_security_group.db.id}"]
  publicly_accessible       = "true"
  license_model             = "postgresql-license"
  skip_final_snapshot       = "false"
  final_snapshot_identifier = "${var.app-name}-final"
  storage_encrypted         = "true"
  backup_retention_period   = "${local.backup_retention_period}"
  backup_window             = "01:00-03:00"
  maintenance_window        = "Sun:03:00-Sun:06:00"

  tags = "${var.tags}"
}
