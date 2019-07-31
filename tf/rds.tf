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

resource "aws_db_instance" "mysql" {
  allocated_storage       = 5
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "5.6.40"
  instance_class          = "db.t2.micro"
  identifier              = "mysql-helloworld"
  name                    = "helloworld"
  username                = "flask"
  password                = "jiu32ijdw8juidewqAI8O"
  db_subnet_group_name    = "${aws_db_subnet_group.rds.name}"
  parameter_group_name    = "default.mysql5.6"
  backup_retention_period = 7
  backup_window           = "10:04-10:34"
  vpc_security_group_ids  = [
      "${aws_security_group.mysql.id}"
  ]
  tags {
      Name     = "mysql-helloworld"
  }
}

output "mysql_endpoint" {
  value = "${aws_db_instance.mysql.endpoint}"
}
