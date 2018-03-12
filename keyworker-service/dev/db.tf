
resource "aws_db_subnet_group" "db" {
  name       = "keyworker-db-dev"
  subnet_ids = ["${aws_subnet.db-a.id}", "${aws_subnet.db-b.id}"]

  tags {
    Name = "keyworker db dev"
  }
}

resource "aws_security_group" "db" {
  name = "db-keyworker-dev-group"
  vpc_id = "${aws_vpc.vpc.id}"
  description = "Db security group"

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = ["${var.ips["office"]}", "${var.ips["mojvpn"]}"]
    security_groups = [ "${aws_security_group.ec2.id}" ]
  }

  tags {
    Name = "${merge(var.tags, map("Name", "${var.app-name}-db-sg"))}"
  }
}

resource "aws_db_instance" "db" {
  identifier           = "keyworker-db-dev"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "10.1"
  instance_class       = "db.t2.micro"
  name                 = "keyworkerdbdev"
  username             = "keyworker"
  password             = "${data.aws_ssm_parameter.keyworker-db-password.value}"
  db_subnet_group_name = "${aws_db_subnet_group.db.name}"
  vpc_security_group_ids = ["${aws_security_group.db.id}"]
  publicly_accessible  = "false"
  license_model        = "postgresql-license"
  skip_final_snapshot  = "true"
  storage_encrypted    = "false"
}

