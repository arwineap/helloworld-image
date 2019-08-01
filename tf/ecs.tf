resource "aws_ecs_cluster" "main" {
  name = "cluster"
}

resource "aws_security_group" "ecs_app" {
  name        = "ecs_app"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Security group for ECS tasks"

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = "ecs_app"
  }
}

resource "aws_security_group_rule" "ecs_app_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ecs_app.id}"
}

resource "aws_security_group_rule" "ecs_app_port" {
  type              = "ingress"
  from_port         = "${var.app_port}"
  to_port           = "${var.app_port}"
  protocol          = "tcp"
  source_security_group_id = "${aws_security_group.alb_main.id}"
  security_group_id = "${aws_security_group.ecs_app.id}"
}

data "template_file" "app" {
  template = "${file("./templates/ecs_app.json.tpl")}"

  vars = {
    app_image      = "${var.app_image}"
    app_port       = "${var.app_port}"
    fargate_cpu    = "${var.fargate_cpu}"
    fargate_memory = "${var.fargate_memory}"
    aws_region     = "us-east-1"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app-task"
  task_role_arn            = "${aws_iam_role.ecs_task_execution_role.arn}"
  execution_role_arn       = "${aws_iam_role.ecs_task_execution_role.arn}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
  container_definitions    = "${data.template_file.app.rendered}"
}

resource "aws_ecs_service" "main" {
  name            = "helloworld-image-service"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = "${var.min_app_count}"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = ["${aws_security_group.ecs_app.id}"]
    subnets          = ["${aws_subnet.internal.*.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.app.id}"
    container_name   = "app"
    container_port   = "${var.app_port}"
  }
  depends_on = ["aws_alb_listener.fe", "aws_iam_role_policy_attachment.ecs_task_execution_role"]
}
