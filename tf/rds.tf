resource "aws_security_group" "mysql" {
  name        = "mysql"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Security group for mysql"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = "mysql"
  }
}

resource "aws_security_group_rule" "mysql_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.mysql.id}"
}

resource "aws_security_group_rule" "allow_mysql" {
  type              = "ingress"
  from_port         = "3306"
  to_port           = "3306"
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.ecs_app.id}"
  security_group_id = "${aws_security_group.mysql.id}"
}


resource "aws_db_subnet_group" "rds" {
  name = "rds"
  subnet_ids = ["${aws_subnet.internal.*.id}"]
  tags {
      Name = "rds subnet group"
  }
}

resource "aws_rds_cluster_parameter_group" "cluster" {
  name        = "aurora-cluster-parameter-group"
  family      = "aurora5.6"
  description = "aurora-cluster-parameter-group"
}

resource "aws_db_parameter_group" "db" {
  name        = "aurora-parameter-group"
  family      = "aurora5.6"
  description = "aurora-parameter-group"
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                        = "2"
  db_subnet_group_name         = "${aws_db_subnet_group.rds.id}"
  cluster_identifier           = "${aws_rds_cluster.cluster.id}"
  publicly_accessible          = "false"
  instance_class               = "db.t3.medium"

  db_parameter_group_name      = "${aws_db_parameter_group.db.name}"

  identifier = "${aws_rds_cluster.cluster.id}-${count.index + 1}"

  tags {
    Name        = "${aws_rds_cluster.cluster.id}-${count.index + 1}"
  }
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier_prefix       = "helloworld-image-"
  availability_zones              = ["${var.availability_zones}"]
  engine                          = "aurora"
  database_name                   = "helloworld"
  master_username                 = "flask"
  master_password                 = "${data.aws_kms_secrets.aurora.plaintext["aurora_master_password"]}"
  vpc_security_group_ids          = ["${aws_security_group.mysql.id}"]
  db_subnet_group_name            = "${aws_db_subnet_group.rds.id}"
  port                            = "3306"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.cluster.name}"
}

data "aws_kms_secrets" "aurora" {
  secret {
    name    = "aurora_master_password"
    payload = "AQICAHhsKNpgZ85glV2MixU0VSJIrCyQa5T64D3SU6UvMQvGEwEAWr1TEZ/nyC5dXh49jbhkAAAAdjB0BgkqhkiG9w0BBwagZzBlAgEAMGAGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMKJhcTOGyo2J+Nnx8AgEQgDPUf1MLoaaOqQAKOiISFsyFJ0vw5OfwMuvAXjKvnG6iHavPey/I160t1qn3gX5oktfwjkc="
  }
}


resource "aws_route53_record" "db_private" {
 zone_id = "${aws_route53_zone.foobar_internal.id}"
 name    = "db.foobar.internal"
 type    = "A"

 alias {
   name                   = "${aws_rds_cluster.cluster.endpoint}"
   zone_id                = "${aws_rds_cluster.cluster.hosted_zone_id}"
   evaluate_target_health = false
 }
}
